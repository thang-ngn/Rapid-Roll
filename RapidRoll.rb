require 'gosu'

module ZOrder
  BACKGROUND, MIDDLE, TOP, NOTICE = *0..3
end

SCREEN_WIDTH = 550
SCREEN_HEIGHT = 700

BACKGROUND_COLOR = Gosu::Color.argb(0xff_fefcd7)

TEXT_SIZE = 25

Y_TOP = 10

HEADER_HEIGHT = 57

$BLOCK_SPEED = 3

#ball
class Ball
  attr_accessor :image, :x, :y, :speed, :drop_speed, :drop_speed2, :alive, :score

  def initialize
    @image = Gosu::Image.new("images/ball.png")
    @x = rand(0 .. SCREEN_WIDTH - @image.width)
    @y = HEADER_HEIGHT + Gosu::Image.new("images/up_thorn.png").height
    @speed = 4
    @drop_speed = @drop_speed2 = 4  #drop_speed2 is used to store another value of dropping speed so that we can change value of drop_speed and after that turn it back to the value before changing
    @alive = true
    @score = 0
  end
end

def draw_ball ball
  if ball.alive
    ball.image.draw(ball.x,ball.y,ZOrder::MIDDLE)
  end
end

def remove_ball ball
  if ball.y >= SCREEN_HEIGHT || ball.y <= HEADER_HEIGHT + Gosu::Image.new("images/up_thorn.png").height
    ball.alive = false
    @hearts.pop           #remove 1 heart if the ball dies
  end
end

#if the ball touches a block, it will stop falling
def stop_ball
  @blocks.each do |block|
    dist = block.y - (@ball.y + @ball.image.height)
    if (dist <= 0 && dist > - @ball.image.height/3) && (@ball.x >= block.x - @ball.image.width) && (@ball.x <= block.x + block.image.width)
      if block.is_thorn
        @ball.alive = false
        @hearts.pop
        break
      else
        @ball.y = block.y - @ball.image.height
        @ball.drop_speed = - block.speed
      end
    end
  end
end

#if the ball leaves a block, it will continue falling
def leave_block
  if @ball.drop_speed != @ball.drop_speed2
    @blocks.each do |block|
      dist = block.y - (@ball.y + @ball.image.height)
      if ((@ball.x + @ball.image.width <= block.x) || (@ball.x >= block.x + block.image.width)) && (dist <= 0 && dist > -@ball.image.height/3)
        @ball.drop_speed = @ball.drop_speed2
      end
    end
  end
end

def move_left ball
  ball.x -= ball.speed
  if ball.x < 0
    ball.x = 0
  end
end

def move_right ball
  ball.x += ball.speed
  if ball.x + ball.image.width >= SCREEN_WIDTH
    ball.x = SCREEN_WIDTH - ball.image.width
  end
end

def drop_down ball
  ball.y += ball.drop_speed
end

#detect when the ball hits a heart to gain life
def gain_extra_heart
    @extraHearts.each do |extraHeart|
      if extraHeart != nil
        dist = Gosu.distance(@ball.x + @ball.image.width/2,@ball.y + @ball.image.height/2,extraHeart.x + extraHeart.image.width/2, extraHeart.y + extraHeart.image.height/2)
          if dist <= @ball.image.width/2 + extraHeart.image.width/2 #&& dist >= @ball.image.width/2 + extraHeart.image.width/2 - 3
            @extraHearts.delete(extraHeart)
            @hearts << Heart.new()
          end
        end
    end
end


#thorn
class Thorn
  attr_accessor :image, :x, :y, :speed, :is_thorn
  def initialize
    @image = Gosu::Image.new("images/thorn.png")

    @x = rand(0 .. SCREEN_WIDTH - @image.width)
    @y = SCREEN_HEIGHT

    @speed = $BLOCK_SPEED

    @is_thorn = true
  end
end


#blocks
class Block
  attr_accessor :image, :x, :y, :speed, :is_thorn

  def initialize
    @image = Gosu::Image.new("images/block.png")

    @x = rand(0 .. SCREEN_WIDTH - @image.width)
    @y = SCREEN_HEIGHT

    @speed = $BLOCK_SPEED

    @is_thorn = false
  end
end

def draw_block block
  block.image.draw(block.x, block.y, ZOrder::MIDDLE)
end

def remove_block
  @blocks.each do |block|
    if block.y < HEADER_HEIGHT + Gosu::Image.new("images/up_thorn.png").height - block.image.height
      @blocks.delete(block)
      @ball.score += 1
    end
  end
end

#hearts (located in the header)
class Heart
  attr_accessor :image, :x, :y

  def initialize
    @image = Gosu::Image.new("images/Vietnam_heart.png")
  end
end

def remove_heart hearts
    hearts.pop
end

def draw_hearts hearts
  i = 0
  while i < hearts.length
    hearts[i].image.draw(i*(hearts[i].image.width + 5) + 10,Y_TOP,ZOrder::TOP)
    i += 1
  end
end

class ExtraHeart
  attr_accessor :image, :x, :y, :speed

  def initialize
    @image = Gosu::Image.new("images/Vietnam_heart.png")
    @x = nil
    @y = nil
    @speed = nil
  end
end

def create_extra_heart blocks
  i = blocks.length - 1
  if blocks[i].is_thorn
    extraHeart = nil
  else
    extraHeart = ExtraHeart.new()
    extraHeart.x = blocks[i].x + blocks[i].image.width/2.5
    extraHeart.y = blocks[i].y - extraHeart.image.height
    extraHeart.speed = $BLOCK_SPEED
  end

  extraHeart
end

def draw_extra_heart extraHeart
  extraHeart.image.draw(extraHeart.x,extraHeart.y,ZOrder::MIDDLE)
end


class RapidRoll < Gosu::Window
  def initialize
    super SCREEN_WIDTH, SCREEN_HEIGHT, false
    self.caption = "Rapid Roll"
    @blocks = Array.new()

    @hearts = [Heart.new, Heart.new, Heart.new]

    @extraHearts = Array.new()

    @ball = Ball.new()

    @font = Gosu::Font.new(TEXT_SIZE) #initialize font of score
    @block_time = 0   #initialize the value of block_time, if block_time reaches the value of block_appear_time, another block will come out
    @block_appear_time = 60   #initialize the appearing time of first 2 blocks
    @thorn_random = 5   #the frequency that a thorn appears (used in update)

    @time = 0   #initialize elapsed time

    @block_appear_time_min = 45   #used to random block_appear_time from the third block
    @block_appear_time_max = 75   #used to random block_appear_time from the third block

    @extraHeart_frequency = 4     #initialize the frequency of appearing extra heart
  end


  #determine the game is over or not
  def game_over
    if @hearts.empty?
      @game_over = true
      @game_over_notice = Gosu::Image.new("images/game_over.jpg")
    end
  end

  #increase game speed to make it harder over time
  def increase_speed
    if @time%2000 == 0 && @time > 0 && @time <= 6000
      @ball.speed += 0.75           #increase ball moving speed when speed of blocks increases
      @ball.drop_speed += 1         #increase ball dropping speed when speed of blocks increases
      @ball.drop_speed2 += 1
      @blocks.each {|block| block.speed += 1}     #make speed of existing blocks increase
      if @extraHearts.empty? == false
        @extraHearts.each do |extraHeart|
          if extraHeart != nil
            extraHeart.speed += 1                 #increase speed of existing extraHearts to make it equal to speed of blocks
          end
        end
      end

      $BLOCK_SPEED += 1                           #increase speed of new blocks

      @block_appear_time_min -= 15*(2000/@time)
      @block_appear_time_max -= 15*(2000/@time)

      @extraHeart_frequency -= 1                  #reduce the frequency of appearing extraHeart
    end
  end

  def update
    @time = @time + 1

    @block_time += 1
    #create new block_appear_time
    if @block_time == @block_appear_time
      @block_time = 0
      @block_appear_time = rand(@block_appear_time_min .. @block_appear_time_max)
    end

    #add a thorn or a block to the array @blocks
    if @block_time == 0
      if rand(@thorn_random) < 1 &&  !@blocks.any? {|block| block.is_thorn == true} && !@blocks.empty?
        block = Thorn.new
      else
        block = Block.new
      end
      @blocks << block
    end

    #assign speed to blocks
    if @blocks.length != 0
      @blocks.each {|block| block.y -= block.speed}
    end

    if Gosu.milliseconds > 500 && @ball.alive       #remove_ball only functions after the game starts
      remove_ball(@ball)
    end

    #if the ball is not alive, this block of code will be executed
    if @ball.alive == false
      if !@blocks.empty?
        if @blocks.length > 2
          i = rand(1 ... @blocks.length)
          while @blocks[i.to_i].is_thorn
            i = rand(1 ... @blocks.length)
          end
        else
          i = rand(0 ... @blocks.length)
          while @blocks[i.to_i].is_thorn
            i = rand(0 ... @blocks.length)
          end
        end

        @ball.x = @blocks[i.to_i].x
        @ball.y = @blocks[i.to_i].y - @ball.image.height
        @ball.alive = true
      end
    end

    #if the ball is alive, this block of code will be executed
    if @ball.alive
      @ball.drop_speed = @ball.drop_speed2
      if @ball.x >= 0 && @ball.x <= (SCREEN_WIDTH - @ball.image.width)
        if Gosu.button_down?(Gosu::KB_RIGHT) or Gosu.button_down?(Gosu::KB_D)
          move_right(@ball)
        elsif Gosu.button_down?(Gosu::KB_LEFT) or Gosu.button_down?(Gosu::KB_A)
          move_left(@ball)
        end

        stop_ball

        leave_block

        remove_block
      end
    end

    #create new extra heart
    if rand(1000) < @extraHeart_frequency && !@blocks.empty?
      extraHeart = create_extra_heart(@blocks)
      @extraHearts << extraHeart
    end

    #assign speed to extra hearts
    if !@extraHearts.empty?
      @extraHearts.each do |extraHeart|
        if extraHeart!= nil
          extraHeart.y -= extraHeart.speed
        end
      end
    end

    drop_down(@ball)

    game_over

    increase_speed

    gain_extra_heart

    #ensure that the maximum number of lives is 5
    while @hearts.length > 5
      @hearts.pop
    end
  end


  def draw_background
    Gosu.draw_rect(0,0,SCREEN_WIDTH,SCREEN_HEIGHT,BACKGROUND_COLOR,ZOrder::BACKGROUND)
  end

  def draw_header
    Gosu.draw_rect(0,0,SCREEN_WIDTH,HEADER_HEIGHT,Gosu::Color::BLUE,ZOrder::TOP)
  end

  def draw_up_thorn
    up_thorn = Gosu::Image.new("images/up_thorn.png")
    up_thorn.draw(0,HEADER_HEIGHT,ZOrder::TOP,scale_x=1,scale_y=1)
  end


  def draw
    draw_background

    draw_header

    draw_up_thorn

    @blocks.each do |block|
      draw_block(block)
    end

    @extraHearts.each do |extraHeart|
      if extraHeart != nil
        draw_extra_heart(extraHeart)
      end
    end


    draw_hearts(@hearts)

    draw_ball(@ball)

    @font.draw_text(@ball.score, SCREEN_WIDTH - 50, Y_TOP + 8, ZOrder::TOP, scale_x = 1, scale_y = 1, Gosu::Color::WHITE)   #draw the score

    #if the game is over, draw a notice on the screen
    if @game_over
      @game_over_notice.draw(0,0,ZOrder::NOTICE)
    end
  end

  def button_down(id)
    case id
    when Gosu::KB_SPACE   #when the game is over, press SPACE to replay and set everything to the beginning
      if @game_over
        @game_over = false
        @hearts = [Heart.new, Heart.new, Heart.new]
        @ball.score = 0
        @blocks.clear
        @extraHearts.clear
        @ball.y = HEADER_HEIGHT + Gosu::Image.new("images/up_thorn.png").height + 5
        @time = 0
        $BLOCK_SPEED = 3
        @ball.drop_speed = @ball.drop_speed2 = 4
        @ball.speed = 4

        @block_appear_time_min = 45
        @block_appear_time_max = 75

        @extraHeart_frequency = 4
      end
    end
  end
end

RapidRoll.new.show
