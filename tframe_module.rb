module Tframes

    def Tframes.contents
        defs = Tframes.methods false
        for d in defs.sort
            puts d 
        end 
        return false
    end 

    def Tframes.test()
        puts "test"
    end 
    def Tframes.get_vertices(edge, rounding_factor)
        if edge.class == Array
            edgething = edge[0] 
        else   
            edgething = edge  
        end

        p_start = edgething.start.position.to_a
        index = 0...p_start.length
        for i in index
            p_start[i] = p_start[i].round(rounding_factor)
        end

        p_end = edgething.end.position.to_a
        index = 0...p_end.length
        for i in index
            p_end[i] = p_end[i].round(rounding_factor)
        end

        return p_start, p_end
    end

    def Tframes.selection_to_extrusion_object_positions(sketchup_sel_of_object = Sketchup.active_model.selection, rounding_factor = 5)
        # assume the edges form either a loop or a line.
        sketchup_edges = (0...sketchup_sel_of_object.length).collect{|i|sketchup_sel_of_object[i]}
        loose_vectors = Tframes.edges_to_vectors(sketchup_edges, rounding_factor)

        object_positions = Tframes.line_or_loop_organize(loose_vectors, rounding_factor)
        return object_positions 
    end

    def Tframes.loose_vectors_to_points_loop(loose_vectors, rounding_factor = 5)# pairs of positions of each end of a line segment
        unordered = Arrayfunctions.safe_copy_level_one_nested_array(loose_vectors)
        chained = [unordered.pop] # unordered is now one less...
        index = 0...unordered.length
        for i in index
            match = unordered.find{|t|t[0] == chained[-1][1] or t[1] == chained[-1][1]}
            unordered.delete(match)
            if match[0] == chained[-1][1]
                chained << match
            else
                chained << match.reverse
            end
        end 
        # get just the string of vertices, not the start and end pairs of the segments
        string = (0...chained.length).collect{|i|chained[i][0]}
        return string
    end

    def Tframes.alone_face_to_vectors(face_sel = Sketchup.active_model.selection, rounding_factor = 5)
        rf = rounding_factor
        face = face_sel[0]
        sketchup_edges = face.all_connected.select{|s| s.class == Sketchup::Edge}
        group_of_vectors = []
        for edge in sketchup_edges
            vector = [(0...3).collect{|i|edge.start.position.to_a[i].round(rf)}, (0...3).collect{|i|edge.end.position.to_a[i].round(rf)}]
            group_of_vectors << vector 
        end 
        return group_of_vectors 
    end

    def Tframes.sketchup_edge_sel_to_vectors(sketchup_edges = Sketchup.active_model.selection, rounding_factor = 5)
        return Interface.edges_to_vectors(sketchup_edges, rounding_factor)
    end

    def Tframes.any_sel_to_ordered_vectors(sel = Sketchup.active_model.selection, rounding_factor = 5)
        if sel[0].class == Sketchup::Face
            loose_vectors = Tframes.alone_face_to_vectors(sel, rounding_factor)
        elsif sel[0].class == Sketchup::Edge
            loose_vectors = Tframes.sketchup_edge_sel_to_vectors(sel, rounding_factor = 5)
        end 
        organized = Tframes.get_loops_lines_edges(loose_vectors)
        return organized 
    end

    def Tframes.string_pairs(array_of_arrays, start = array_of_arrays[0])
        aoa = array_of_arrays
        length = aoa.length
        index = 0...length
        arranged = [start]
        aoa.delete(start)
        counter = 0
        for i in index
            for a in aoa
                candidate = aoa.find{|a| a[0] == arranged[-1][-1]}
                if  candidate
                    arranged << candidate
                    aoa.delete(candidate)
                    counter += 1
                end
                candidate = aoa.find{|a| a[-1] == arranged[0][0]}
                if candidate
                    arranged.unshift(candidate)
                    aoa.delete(candidate)
                    counter += 1
                end
            end
        end 
        return arranged
    end        

    def Tframes.get_loops_lines_edges(array_of_vectors) # line vectors that are [[position_array], [position_array]]
        array = (0...array_of_vectors.length).collect{|i|array_of_vectors [i]}
        sets = []
        while array.length > 0
            set = Tframes.string_pairs(array, start = array[0])
            sets << set
            array = array - set 
        end
        return sets 
    end  
    

    def Tframes.triangle_perp_distance_and_height(vectorAB, vectorBC, vectorCA, rounding_factor) # vector is [start position, end position]
        # get the lengths of the sides and then the first angle
        magAB = Vectorfunctions.line_vector_length(vectorAB, rounding_factor)
        magBC = Vectorfunctions.line_vector_length(vectorBC, rounding_factor)
        magCA = Vectorfunctions.line_vector_length(vectorCA, rounding_factor)
        radangleAB = Trigfunctions.radian_angles_from_side_lengths(magAB, magBC, magCA)[0]
        # get the height
        height = (magAB * Math.sin(radangleAB)).round(rounding_factor)
        # get the offset of the height perpendicular from the first angle
        offset = ((magAB**2 - height**2)**0.5).round(rounding_factor)
        return height, offset
    end
=begin 
baseline_start = basket[0][0][0]
baseline_end = basket[1][0][0]
top_start = basket[2][0][0]
object_edgeset = t.get_object_points[0]

point = o_e[0]



=end

    def Tframes.baseframe_edgeset_offsets(baseline_start, baseline_end, top_start, object_edgeset, rounding_factor = 5) #2D orthagonal, square baseframe
        # use the bottom and each object point to make a triangle. Use this triangle to get the height perpendicularly
        # from the bottom and the distance along the bottom to the perpendicular.
        rf = rounding_factor
        o_e = Arrayfunctions.safe_copy_level_one_nested_array(object_edgeset)
        offset_pairs = []
        temp = []
        for point in o_e  
            vectorAB = [baseline_start, point]
            vectorBC = [point, baseline_end]
            vectorCA = [baseline_end, baseline_start]
            offset_pairs << Tframes.triangle_perp_distance_and_height(vectorAB, vectorBC, vectorCA, rounding_factor)
        end
        # each object_edgeset point now has a lateral and vertical offset in actual length
        # fractionalize the offset lengths so that they can be applied to the different lengths of the transformation grid
        x_net = (0...3).collect{|e|baseline_end[e] - baseline_start[e]}
        x_mag = (((0...3).collect{|x|x_net[x] * x_net[x]}).sum)**0.5
        y_net = (0...3).collect{|e|top_start[e] - baseline_start[e]}
        y_mag = ((((0...3).collect{|y|y_net[y] * y_net[y]}).sum)**0.5).round(rounding_factor)

        fractional_offsets = offset_pairs.each.collect{|i|[(i[0] / y_mag).round(rf), (i[1] / x_mag).round(rf)]}
        return fractional_offsets
        # returns unsorted 
    end

    def Tframes.offsets_to_transformation_frame_points(t_baseline_start, t_baseline_end, t_top_start, t_top_end, fractional_offsets, rounding_factor = 5)
        offsets = Arrayfunctions.safe_copy_level_one_nested_array(fractional_offsets)
        vertices = []
        for pair in offsets
            bottom_point = Vectorfunctions.segment_by_one_fraction(t_baseline_start, t_baseline_end, pair[1], rounding_factor)
            top_point = Vectorfunctions.segment_by_one_fraction(t_top_start, t_top_end, pair[1], rounding_factor)
            vertex =  Vectorfunctions.segment_by_one_fraction(bottom_point, top_point, pair[0], rounding_factor)
            vertices << vertex
        end
        return vertices
    end

    def Tframes.get_basket(sketchup_sel_of_basket = Sketchup.active_model.selection, rounding_factor = 5)
        # get the loose edges, may a copy that won't mutate the original..
        vectors_source = (0...sketchup_sel_of_basket.length).collect{|i|Tframes.get_vertices(sketchup_sel_of_basket[i], rounding_factor)}
        vectors_collection = vectors_source.each.collect{|segment|segment.each.collect{|point|point.each.collect{|coord| coord}}}
        # get just the positions
        gross_positions_starts = (0...vectors_collection.length).collect{|i|vectors_collection[i][0]} # copy the start positions
        gross_positions_ends = (0...vectors_collection.length).collect{|i|vectors_collection[i][1]} # add the end positions
        gross_positions = []
        for vector in vectors_collection
            gross_positions << vector[0]
            gross_positions << vector[1]
        end
        # find the singleton positions, these are the start and end. first break down the collection into loose positions
        flowguide_starts_unordered = []
        for position in gross_positions
            if gross_positions.count(position) == 1
                flowguide_starts_unordered << position
            end 
        end
        # get the positions which are repeated 3 times. These are the final frame corners and the ends of the flowguides.. this block not used...
        final_frame_corners = []
        for position in gross_positions
            if gross_positions.count(position) == 3
                final_frame_corners << position
            end 
        end
        final_frame_corners = final_frame_corners.uniq
        # get the vectors that contain the flowguide start positions. use a safe copy of the vectors collection which is already unique
        # these are the initial vectors for each flow guide, not the vectors of the base frame which is not represented in the sketchup
        # selection.
        vectors_workset = vectors_collection.each.collect{|segment|segment.each.collect{|point|point.each.collect{|coord| coord}}}
        flowguide_start_vectors = []
        for position in flowguide_starts_unordered
            for vector in vectors_workset
                if vector[0] == position 
                    flowguide_start_vectors << vector 
                elsif
                    vector[1] == position 
                    flowguide_start_vectors << vector
                end 
            end 
        end
        # get the lenghts of each flowguide. the final frame has 4 segments
        positions_collection = gross_positions.uniq
        fg_length = (positions_collection.length - 4) / 4
        # for each flow guide use the start positions to match head to tail for fg_length
        flowguides = []
        for start_vector in flowguide_start_vectors
            single_guide_string = [start_vector]
            vectors_workset.delete(start_vector)
            while single_guide_string.length < fg_length
                for vector in vectors_workset
                    match = single_guide_string[-1][-1]
                    if vector[0] == match
                        single_guide_string << vector
                        vectors_workset.delete(vector)
                    end
                    if
                        vector[1] == match
                        temp = vector
                        single_guide_string << temp.reverse
                        vectors_workset.delete(vector)
                    end   
                end 
            end
            # replace the vectors that the while loop overcounts
            overage = single_guide_string.length - fg_length 
            for o in 0...overage
                last = single_guide_string[-1]
                vectors_workset << last
                single_guide_string.delete(last) 
            end
            flowguides << single_guide_string
        end
        # the vectors left over are the final frame. organize the final frame and use this organization to reorder the flowguides
        # and to create the base frame
        final_frame_positions_loop_circular = Tframes.loose_vectors_to_points_loop(vectors_workset, rounding_factor)
        # get the frame vectors and the flowguides into a standard ordering so it is possible to make use of the parts downstream
        # the order of the frame should be that the top vector goes in the same direction as the bottom vector, and left and right go up
        # from the bottom to the top. In this way the bottom and left can function as x and y axis would.
        # the order of the frame vectors is bottom, left, top, right
        ffplc = final_frame_positions_loop_circular
        final_frame_vectors = [[ffplc[0], ffplc[1]], [ffplc[0], ffplc[3]], [ffplc[3], ffplc[2]], [ffplc[1], ffplc[2]],]
        # align the flowguides with the final frame. positions 3 and 2 are reversed so that the t_frames made with them will naturally
        # have their top and bottom vectors going in the same direction.
        ends_sequence = [ffplc[0], ffplc[1], ffplc[3], ffplc[2]]
        flowguides_ordered = []
        index = 0...ends_sequence.length
        for i in index
            for flowguide in flowguides
                if flowguide[-1][-1] == ends_sequence[i]
                    flowguides_ordered << flowguide 
                end 
            end 
        end 
        fgo = flowguides_ordered
        # now the base frame can be constructed from the flowguide starts
        flowguide_start_positions = (0...fgo.length).collect{|i|fgo[i][0][0]}
        fsp = flowguide_start_positions
        base_frame_vectors = [[fsp[0], fsp[1]], [fsp[0], fsp[2]], [fsp[2], fsp[3]], [fsp[1], fsp[3]]]
        return fgo[0], fgo[1], fgo[2], fgo[3], base_frame_vectors, final_frame_vectors
    end
=begin 
object_edgeset = f.import_object_points[0]
basket = f.import_basket
rounding_factor = 5

x = 50

for s in basket[5]
    d_seg = [[s[0][0] + x, s[0][1], s[0][2]], [s[1][0] + x, s[1][1], s[1][2]]] 
    Sketchup.active_model.entities.add_edges(d_seg)
end

Tframes.baseframe_edgeset_offsets(baseline_start, baseline_end, top_start, object_edgeset, rounding_factor = 5)

baseline_start = basket[0][0][0]
baseline_end = basket[1][0][0]
top_start = basket[2][0][0]



=end

    def Tframes.edgeset_transformations(object_edgeset, basket, rounding_factor = 5)
        flowguides_extracted = basket[0..3]
        # make the flowguides into a string of points
        f0 = flowguides_extracted[0].each.collect{|i|i[0]}
        f0 << flowguides_extracted[0][-1][-1]
        f1 = flowguides_extracted[1].each.collect{|i|i[0]}
        f1 << flowguides_extracted[1][-1][-1]
        f2 = flowguides_extracted[2].each.collect{|i|i[0]}
        f2 << flowguides_extracted[2][-1][-1]
        f3 = flowguides_extracted[3].each.collect{|i|i[0]}
        f3 << flowguides_extracted[3][-1][-1]
        bfpoints = [f0[0], f1[0], f2[0], f3[0]]
        # get the fractional offsets
        fractional_offsets = Tframes.baseframe_edgeset_offsets(bfpoints[0], bfpoints[1], bfpoints[2], object_edgeset, rounding_factor = 5)
        # for each flow line segment create a transformation plane and map the object onto it using the offsets.
        index = 0...f0.length
        t_edgesets = []
        for i in index
            transformed_edgeset = Tframes.offsets_to_transformation_frame_points(f0[i], f1[i], f2[i], f3[i], fractional_offsets, rounding_factor = 5)
            t_edgesets << transformed_edgeset
        end
        return t_edgesets
    end

    def Tframes.extrude_from_transformation_edgesets(t_edgesets)
        extrusion_index = 0...(t_edgesets.length)-1
        all_faces  = []
        for e in extrusion_index
            faces = Tframes.faceify_ribbon(t_edgesets[e], t_edgesets[e+1])
            all_faces << faces
        end
        return all_faces
    end

    def Tframes.faceify_ribbon(pointset_1, pointset_2)
        # convert to quadrants
        quadrants = []
        index =  0...(pointset_1.length) - 1
        for i in index
            quad = [pointset_1[i], pointset_1[i+1], pointset_2[i+1], pointset_2[i]]
            quadrants << quad 
        end
        # facify the quadrants
        faces_a = []
        for q in quadrants
            face1 = Sketchup.active_model.entities.add_face(q[0], q[1], q[2])
            faces_a << face1
            face2 = Sketchup.active_model.entities.add_face(q[3], q[0], q[2])
            faces_a << face2
        end 
        return faces_a
    end

end