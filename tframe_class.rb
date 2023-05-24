class Tx

    def initialize()
    end 

    def rf(value = 5)
        @rounding_factor = value 
        return value
    end
    
    def get_rf
        @rounding_factor 
    end

    def import_basket(sketchup_edges = Sketchup.active_model.selection) 
        @basket = Tframes.get_basket(sketchup_edges, @rounding_factor)
    end

    def get_basket
        @basket 
    end 

    def import_object_points(sketchup_edges = Sketchup.active_model.selection)
        @object_vectors = Tframes.any_sel_to_ordered_vectors(sel = Sketchup.active_model.selection, @rounding_factor)
        # make points loop out of vectors loop
        points_sets = []
        for set in @object_vectors
            points_set = (0...set.length).collect{|i|set[i][0]}
            points_set << points_set[0]
            points_sets << points_set
        end
        @object_points = points_sets
    end

    def get_object_points 
        @object_points
    end
=begin 
load "G:/My Drive/Education/Programming Related/Ruby/array_stuff_loader.rb"
g = Tx.new
g.rf
g.import_basket
g.import_object_points

extrusion_set = []
for edgeset in f.get_object_points
    transformed_edgesets = Tframes.edgeset_transformations(edgeset, f.get_basket, f.get_rf)
    extrusion_set << transformed_edgesets
end

=end

    def extrude
        t_edgesets
        extrude_edgesets 
    end

    def t_edgesets
        @extrusion_sets = []
        for edgeset in @object_points
            transformed_edgesets = Tframes.edgeset_transformations(edgeset, @basket, @rounding_factor)
            @extrusion_sets << transformed_edgesets
        end
        return @extrusion_sets 
    end

    def extrude_edgesets 
        @face_sets
        for set in  @extrusion_sets 
            face_set = Tframes.extrude_from_transformation_edgesets(set)
            @face_sets << face_set
        end  
        return @face_sets
    end


    def get_tframes
        @extrusion_set 
    end

    def delete
        for face in @faces.flatten
            face.erase! 
        end 
    end

    def get_faces
        @faces 
    end





=begin 

load "G:/My Drive/Education/Programming Related/Ruby/array_stuff_loader.rb"

g = Tx.new
g.rf(5)
basket = g.import_basket
object_points = g.import_object_points
g.extrude
g.get_faces
g.get_tfames
g.delete



for face in c.get_faces.flatten
    face.erase!
end

sizes = []
for set in x.t_edgesets[0]
    sizes << set.length 
end
sizes = x.t_edgesets.each{|set|set.length}


for pointset in object

extrusion_set = []
for edgeset in object_points
    transformed_edgesets = Flowtrude.fourtrude_edgeset_transformations(edgeset, basket, @rounding_factor)
    extrusion_set << transformed_edgesets
end

set_1 = Flowtrude.fourtrude_edgeset_transformations(object_points[0], basket, k.get_rf)
set_2 = Flowtrude.fourtrude_edgeset_transformations(object_points[1], basket, k.get_rf)

Flowtrude.extrude_from_transformation_edgesets(set_1)
Flowtrude.extrude_from_transformation_edgesets(set_2)

for entity in face.all_connected
    entity.erase!
end

point1 = 


=end


end