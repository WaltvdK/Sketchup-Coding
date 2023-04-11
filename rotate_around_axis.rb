

def Rotate_point_about_axis(axis_startpt, axis_endpt, point_to_be_rotated, radians, rounding_factor = 5)
    # copy and simplify the arguements so that the originals don't get modified inadvertently.
    rf = rounding_factor
    axis_endpt = (0...3).collect{|i|axis_endpt[i].round(rf)}
    axis_startpt = (0...3).collect{|i|axis_startpt[i].round(rf)}
    rot_point = (0...3).collect{|i|point_to_be_rotated[i].round(rf)}
    rads = radians.round(rf)

    # Get the projected point on the axis. Imagine a line going from the point to be rotated to the axis such that the line is at 
    # right angles to the axis. Call this line the baseline. The meeting point this baseline and the axis is the projected point. 
    # The baseline is in the plane in which the rotation will take place.
    # see Sketchup documentation at https://ruby.sketchup.com/Geom/Point3d.html#project_to_line-instance_method

    baseline = [Geom::Point3d.new(axis_startpt), Geom::Point3d.new(axis_endpt)]
    point = Geom::Point3d.new(rot_point)
    projected_point = point.project_to_line(baseline)

    # Imagine another line that is normal to the baseline and the axis. This means it is at 90 degrees to both and will also be
    # in the plane of rotation. The projection point is the point around which the point to be rotated will revolve, so if
    # the normal line passes through it, the normal line could act as a y axis for the rotation plane. the baseline could be the x_axis. 
    # In sketchup vectors are used to represent lines that have direction and length but not position. They are the equivalent
    # to the end point that any line would have if it was moved so that it's start point was at the origin. Given 2 vectors like
    # this sketchup can compute another normal vector to them. 
    # Move the baseline and the axis to the origin and convert them to sketchup vectors. ( Use just a portion of the axis with the
    # projected point at one end )
    # see https://ruby.sketchup.com/Geom/Point3d.html#initialize-instance_method

    baseline_vector = Geom::Vector3d.new((0...3).collect{|i|rot_point[i] - projected_point[i]})
    axis_line_vector = Geom::Vector3d.new((0...3).collect{|i|axis_startpt[i] - projected_point[i]})

    # now the normal position vector can be obtained using the cross product. Again, this is a vector perpendicular to both the baseline vector
    # and the axis_line_vector. It has its start point at the origin and is represented by just its endpoint. How the cross product actually works
    # is not explained here but see note below.
    # see https://ruby.sketchup.com/Geom/Vector3d.html#cross-instance_method

    normal_vector = baseline_vector.cross(axis_line_vector)
    
    #( Note that it is possible to end up with a final result that is a rotaion with the opposite sign angle to what was input. 
    # This can happen if the axis line startpt is either "below", or "above" the rotation point. It will be one or the other but the 
    # one will result in the normal being in the opposite direction to the other. As there is no such thing as up or down in general 
    # in 3D space, the only way to control for this is by adjusting the function arguement axis startpt and axis endpt as the situation requires) 

    # Consider the baseline vector and the normal vector to represent a plane as mentioned above. They meet at the origin of this plane and are at
    # right angles to each other. The baseline will rotate by the radians amount and its end point will then be at the location being sought.
    # These operations can be carried out while the imaginary plane is located with the projection point at the origin and then
    # the rotated point can be translated back to its correct position using the vector from the origin to the actual projection point ( which
    # is just the projection point itself ) You could call the plane with the projection point at the origin the zero plane. Note that it is
    # not the same as the xyz plane native to sketchup itself, it just shares the origin.

    x_direction_unit_vector = Geom::Vector3d.new( baseline_vector.to_a.each.collect{|i| i /  baseline_vector.length})
    y_direction_unit_vector = Geom::Vector3d.new(normal_vector.to_a.each.collect{|i| i / normal_vector.length})
    

    # now consider the angle of rotation in an xy plane. Math.cos(radians) will give you the distance along the x axis of a right triangle
    # of which the hypotenuse is length one. but the hypotenuse is the length of the baseline because the rotated point is the same
    # as rotating the baseline.( There are the four right angles of a circle in which either the cosine or sine are zero. This would involve
    # division by zero. This is not considered here.) 
    #...So the cosine length of the rotated point will be:
    
    cosine_length = Math.cos(radians) * baseline_vector.length

    # This position can be found using the sketchup length= method. This will change the value of the vector being resized so make a piecemenal copy..
    # Probably a simpler way is just to multiply each of the coordinates by the scalar..
    # see https://ruby.sketchup.com/Geom/Vector3d.html#length=-instance_method

    temp = Geom::Vector3d.new(x_direction_unit_vector.to_a.each.collect{|i|i})
    temp.length= (cosine_length)
    cosine_position = temp

    # Now the distance between the cosine positon and the rotatied point will be the sine value of the triangle. This can be calculated in the
    # same way as the cosine.

    sine_length = Math.sin(radians) * baseline_vector.length

    # Multipy the y_direction_unit_vector by the sine length to get the sine vector. Note that this is a portion of the y axis that is
    # equivalent to the sine length. In this situation it is a proper vector that starts in the origin and whose end point is the
    # value of the vector.

    temp = Geom::Vector3d.new(y_direction_unit_vector.to_a.each.collect{|i|i})
    temp.length= (sine_length)
    sine_vector = temp

    # add this vector to the cosine position to get the rotation point on the zero plane being evaluated. Vector3D objects can be added directly
    # see https://ruby.sketchup.com/Geom/Vector3d.html#%2B-instance_method

    zero_plane_rotation_point = cosine_position + sine_vector

    # now add the vector representing the original projection point to this zero_plane_rotation_point to get the final answer.

    rotated_point = zero_plane_rotation_point + Geom::Vector3d.new(projected_point.to_a)

    return rotated_point

end

