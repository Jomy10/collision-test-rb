module Collision
  # https://flatredball.com/documentation/tutorials/math/circle-collision/
  def self.circles_collide(circle1, circle2)
    # x2 = circle2.x + circle2.radius
    # y2 = circle2.y + circle2.radius
    # x1 = circle1.x + circle1.radius
    # y1 = circle1.y + circle1.radius
    distBetweenCirclesSquared =
      (circle2.x - circle1.x)*(circle2.x - circle1.x) +
      (circle2.y - circle1.y)*(circle2.y - circle1.y)
      # (x2 - x1) * (x2 - x1) +
      # (y2 - y1) * (y2 - y1)

    return distBetweenCirclesSquared < (circle1.radius + circle2.radius)*(circle1.radius + circle2.radius)
  end
end
