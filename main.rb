require 'kiwi-ecs'
require 'ruby2d'
require_relative 'collision'
require_relative 'physics'

COUNT = 250
VEL_MUL = 1

W = 600
H = 400
VEL_S = 25.0

set width: W, height: H

class Vec2
  attr_accessor :x
  attr_accessor :y
  
  def initialize(x, y)
    @x = x.to_f
    @y = y.to_f
  end
  
  def self.splat(f)
    return Vec2.new(f, f)
  end
  
  def +(other)
    if (other.is_a? Vec2)
      return Vec2.new(self.x + other.x, self.y + other.y)
    elsif (other.is_a? Float)
      return Vec2.new(self.x + other, self.y + other)
    elsif (other.is_a? Integer)
      return self + other.to_f
    else
      raise 'uninmplemented'
    end
  end

  def -(other)
    if (other.is_a? Vec2)
      return Vec2.new(self.x - other.x, self.y - other.y)
    else
      raise 'uninmplemented'
    end
  end

  def *(other)
    if (other.is_a? Float)
      return Vec2.new(self.x * other, self.y * other)
    elsif (other.is_a? Vec2)
      return Vec2.new(self.x * other.x, self.y * other.y)
    elsif (other.is_a? Integer)
      return self * other.to_f
    else
      raise 'unimplemented'
    end
  end

  def /(other)
    if (other.is_a? Float)
      return Vec2.new(self.x / other, self.y / other)
    elsif (other.is_a? Vec2)
      return Vec2.new(self.x / other.x, self.y / other.y)
    elsif (other.is_a? Integer)
      return self / other.to_f
    else
      raise "unimplemented Vec2 / #{other}"
    end
  end

  def normalized!
    w = Math.sqrt(self.x * self.x + self.y * self.y)
    self.x /= w
    self.y /= w
  end

  def normalize
    w = Math.sqrt(self.x * self.x + self.y * self.y)
    return Vec2.new(self.x / w, self.y / w)
  end

  def dot(other)
    return self.x * other.x + self.y * other.y
  end

  def length
    raise 'todo'
  end
end

def is_close(x1, y1, x2, y2)
  return x1 - 10 < x2 && x1 + 10 > x2 && y1 - 10 < y2 && y1 + 10 > y2
end

Transform = Struct.new(:pos, :vel, :radius)
RenderingShape = Struct.new(:shape)
CollisionHit = Struct.new(:collides_with, :prev_col)

world = Kiwi::World.new

(0...COUNT).each do |_|
  x = rand(W)
  y = rand(H)
  radius = rand(10)
  world.spawn(
    Transform.new(Vec2.new(x, y), Vec2.new(rand(VEL_S) - VEL_S / 2.0, rand(VEL_S) - VEL_S / 2.0), radius),
    RenderingShape.new(Circle.new(x: x, y: y, radius: radius, color: [rand(), rand(), rand(), rand()])),
    CollisionHit.new(nil, nil)
  )
end

on :key_up do |event|
  if event.key == 'escape'
    close
  end
end

last_time = Time.now
update do
  dt = (Time.now - last_time)
  last_time = Time.now

  # Wall collision
  world.query(Transform) do |transf|
    pos = transf[0].pos
    vel = transf[0].vel
    radius = transf[0].radius

    if pos.x - radius < 0
      vel.x = vel.x < 0 ? -vel.x : vel.x
    elsif pos.x + radius > W
      vel.x = vel.x > 0 ? -vel.x : vel.x
    end

    if pos.y - radius < 0
      vel.y = vel.y < 0 ? -vel.y : vel.y
    elsif pos.y + radius > H
      vel.y = vel.y > 0 ? -vel.y : vel.y
    end
  end

  entities = world.query_with_ids(RenderingShape, CollisionHit, Transform).to_a
  entities.each do |id, shape, col, transf|
    entities.each do |id2, shape2, col2, transf2|
      next if id == id2
      next if !col.collides_with.nil?
      next if !col2.collides_with.nil?
      center1 = Vec2.new(shape.shape.x, shape.shape.y)
      center2 = Vec2.new(shape2.shape.x, shape2.shape.y)
      # center1 = Vec2.new(shape.shape.x, shape.shape.y) + shape.shape.radius
      # center2 = Vec2.new(shape2.shape.x, shape2.shape.y) + shape2.shape.radius
      if is_close(shape.shape.x, shape.shape.y, shape2.shape.x, shape2.shape.y) && Collision.circles_collide(shape.shape, shape2.shape)
        next if col.prev_col == id2
        col.collides_with = id2
        col2.collides_with = id
      end
    end
  end

  # Move when collides
  world
    .query(RenderingShape, Transform, CollisionHit)
    # .filter { |_, _, hit| !hit.collides_with.nil? }
    .each do |shape, transf, hit|
      next if hit.collides_with.nil?

      transf2 = world.get_component(hit.collides_with, Transform)

      # Determine a plane normal on the ball collided with
      circle1 = shape.shape
      circle2 = world.get_component(hit.collides_with, RenderingShape).shape

      # planeNormal = Vec2.new(circle1.x - circle2.x, circle1.x - circle2.y).normalize

      # Reflect circle1's vector
      vel1 = transf.vel
      vel2 = transf2.vel

      # reflectedVel = Vec2.splat(2) * (vel1.dot(planeNormal) / planeNormal.dot(planeNormal)) * planeNormal - vel1
      reflectedVel1 = Physics.circle_bounce(circle1, vel1, circle2)
      reflectedVel2 = Physics.circle_bounce(circle2, vel2, circle1)

      transf.vel = reflectedVel1
      transf2.vel = reflectedVel2

      hit2 = world.get_component(hit.collides_with, CollisionHit)
      hit.prev_col = hit.collides_with
      hit2.prev_col = hit2.collides_with
      hit.collides_with = nil
      hit2.collides_with = nil
    end

  # Update positions with velocity
  world.query(Transform) do |transf|
    transf = transf[0] # todo: fix
    transf.pos += transf.vel * dt
  end

  world.query(Transform, RenderingShape) do |transf, rshape|
    rshape.shape.x = transf.pos.x
    rshape.shape.y = transf.pos.y
  end
end

show
