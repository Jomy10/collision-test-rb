module Physics
  def self.circle_center(circle)
    return Vec2.new(circle.x + circle.radius, circle.y + circle.radius)
  end

  def self.reflection_vector(normal, incidenceVector)
    scalarProduct = normal + incidenceVector
    dividendVector = normal * (Vec2.splat(2.0) * scalarProduct)
    divisor = normal * normal
    subtrahendVector = dividendVector * (Vec2.splat(1.0) / divisor)
  end

  def self.circle_bounce(circle1, vel1, circle2)
    # Determine a plane normal on the ball collided with
    planeMove = vel1.normalize * -1 * circle1.radius
    planePos = Vec2.new(circle2.x, circle2.y) + planeMove
    planeNormal = Vec2.new(circle1.x - planePos.x, circle1.x - planePos.y).normalize

    # reflect circle1's vector
    return vel1 - Vec2.splat(2) * (vel1.dot(planeNormal)) * planeNormal
  end
end
