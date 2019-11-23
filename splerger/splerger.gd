extends Reference

class_name Splerger

# debug
var m_bDebug_Split = false


func split_branch(node : Node, grid_size : float):
	var meshlist = []
	var splitlist = []
	
	_find_meshes_recursive(node, meshlist, grid_size)

	# record which meshes have been successfully split .. for these we will
	# remove the original mesh
	splitlist.resize(meshlist.size())

	for m in range (meshlist.size()):
		#if m != 18:
		#	continue
		
		print("mesh " + meshlist[m].get_name())
		#split(meshlist[m], grid_size, node.get_parent())
		
		#if m == 18:
		#	m_bDebug_Split = true
		#else:
	#		m_bDebug_Split = false
		
		if split(meshlist[m], grid_size, node) == true:
			splitlist[m] = true
	
	# just do one for now
	#split(meshlist[0], grid_size, node.get_parent())
	for m in range (meshlist.size()):
		#if splitlist[m] == true:
		var mi = meshlist[m]
		mi.get_parent().remove_child(mi)
			#mi.queue_delete()
	
	print("split_branch FINISHED.")
	pass

func _get_num_splits_x(aabb : AABB, grid_size : float)->int:
	var splits = int (floor (aabb.size.x / grid_size))
	if splits < 1:
		splits = 1
	return splits

func _get_num_splits_z(aabb : AABB, grid_size : float)->int:
	var splits = int (floor (aabb.size.z / grid_size))
	if splits < 1:
		splits = 1
	return splits


func _find_meshes_recursive(node : Node, meshlist, grid_size : float):
	# is it a mesh?
	if node is MeshInstance:
		var mi : MeshInstance = node as MeshInstance
		var aabb : AABB = CalcAABBSlow(mi)
		print ("mesh " + mi.get_name() + "\n\tAABB " + str(aabb))
		
		var splits_x = _get_num_splits_x(aabb, grid_size)
		var splits_z = _get_num_splits_z(aabb, grid_size)
		
		if (splits_x + splits_z) > 2:
			meshlist.push_back(mi)
			print ("\tfound mesh to split : " + mi.get_name())
			print ("\t\tsplits_x : " + str(splits_x) + " _z " + str(splits_z))
			#print("\tAABB is " + str(aabb))
	
	for c in range (node.get_child_count()):
		_find_meshes_recursive(node.get_child(c), meshlist, grid_size)


func CalcAABBSlow(mesh_instance : MeshInstance):
	var aabb : AABB = mesh_instance.get_transformed_aabb()
	
#	var mesh = mesh_instance.mesh
#	var mdt = MeshDataTool.new()
#	mdt.create_from_surface(mesh, 0)
#	var nVerts = mdt.get_vertex_count()
#
#	var xform = mesh_instance.global_transform
#	var aabb : AABB
#
#	for n in range (nVerts):
#		var vert = mdt.get_vertex(n)
#		vert = xform.xform(vert)
#		if n == 0:
#			aabb.position = vert
#			aabb.size = Vector3(0, 0, 0)
#		else:
#			aabb = aabb.expand(vert)
#
#	_check_aabb(aabb)
	# godot intersection doesn't work on borders ...
	aabb = aabb.grow(0.1)
	return aabb		

func _check_aabb(aabb : AABB):
	assert (aabb.size.x >= 0)
	assert (aabb.size.y >= 0)
	assert (aabb.size.z >= 0)
	

# split a mesh according to the grid size
func split(mesh_instance : MeshInstance, grid_size : float, attachment_node : Node, delete_orig : bool = false):
	# get the AABB
	var aabb : AABB = CalcAABBSlow(mesh_instance)
	#var aabb = mesh_instance.get_transformed_aabb()
	var x_splits : int = _get_num_splits_x(aabb, grid_size)
	var z_splits : int = _get_num_splits_z(aabb, grid_size)

	print (mesh_instance.get_name() + " : x_splits " + str(x_splits) + " z_splits " + str(z_splits))

	## no need to split .. should never happen
	if ((x_splits + z_splits) == 2):
		print ("WARNING - not enough splits, ignoring")
		return false
	
	var mesh = mesh_instance.mesh

	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	var nVerts = mdt.get_vertex_count()
	if nVerts == 0:
		return true

	# new .. create pre transformed to world space verts, no need to transform for each split
	var world_verts = PoolVector3Array([Vector3(0, 0, 0)])
	world_verts.resize(nVerts)
	var xform = mesh_instance.global_transform
	for n in range (nVerts):
		world_verts.set(n, xform.xform(mdt.get_vertex(n)))

	print ("\tnVerts " + str(nVerts))

	# only allow faces to be assigned to one of the splits
	# i.e. prevent duplicates in more than 1 split
	var nFaces = mdt.get_face_count()
	var faces_assigned = []
	faces_assigned.resize(nFaces)

	# each split
	for z in range (z_splits):
		for x in range (x_splits):
			_split_mesh(mdt, mesh_instance, x, z, x_splits, z_splits, aabb, attachment_node, faces_assigned, world_verts)
			
			
	# delete the orig
	#mesh_instance.get_parent().remove_child(mesh_instance)
	#mesh_instance.queue_free()
	
	return true


#class UniqueVert:
#	var m_OrigInd : int



func _split_mesh(mdt : MeshDataTool, orig_mi : MeshInstance, grid_x : float, grid_z : float, xsplits : int, zsplits : int, orig_aabb : AABB, attachment_node : Node, faces_assigned, world_verts : PoolVector3Array):

	print ("\tsplit " + str(grid_x) + ", " + str(grid_z))

	# find the subregion of the aabb
	var xgap = orig_aabb.size.x / xsplits
	var zgap = orig_aabb.size.z / zsplits
	var pos = orig_aabb.position
	pos.x += grid_x * xgap
	pos.z += grid_z * zgap
	var aabb = AABB(pos, Vector3(xgap, orig_aabb.size.y, zgap))
	
	# godot intersection doesn't work on borders ...
	aabb = aabb.grow(0.1)
	
	if m_bDebug_Split:
		print("\tAABB : " + str(aabb))

	var nVerts = mdt.get_vertex_count()
	var nFaces = mdt.get_face_count()
	
	# find all faces that overlap the new aabb and add them to a new mesh
	var faces = []

	var face_aabb : AABB

	var bDebug = false
	if m_bDebug_Split && (grid_x == 0) && (grid_z == 0):
		bDebug = true
	var sz = ""
	
	var xform = orig_mi.global_transform
	
	for f in range (nFaces):
		if (f % 2000) == 0:
			print (".")
		#if bDebug:
		#	sz = "face " + str(f) + "\n"
		
		for i in range (3):
			var ind = mdt.get_face_vertex(f, i)
			#var vert = mdt.get_vertex(ind)
			#vert = xform.xform(vert)
			var vert = world_verts[ind]

			#if bDebug:
			#	sz += "v" + str(i) + " " + str(vert) + "\n"
			
			
			if i == 0:
				face_aabb = AABB(vert, Vector3(0, 0, 0))
			else:
				face_aabb = face_aabb.expand(vert)
				
		#if bDebug:
		#	print(sz)
			
		# does this face overlap the aabb?
		if aabb.intersects(face_aabb):
			# only allow one split to contain a face
			if faces_assigned[f] != true:
				faces.push_back(f)
				faces_assigned[f] = true

		# debug test if outside original AABB
		#if face_aabb.intersects(orig_aabb) == false:
		#	print("ERROR FACE OUTSIDE AABB: ")
		#	print("orig_aabb " + str(orig_aabb))
		#	print("face_aabb " + str(face_aabb) + "\n")
			
		

	if faces.size() == 0:
		print("\tno faces, ignoring...")
		return

	# find unique verts
	var new_inds = []
	var unique_verts = []

	print ("mapping start")
	# use a mapping of original to unique indices to speed up finding unique verts	
	var ind_mapping = []
	ind_mapping.resize(mdt.get_vertex_count())
	for i in range (mdt.get_vertex_count()):
		ind_mapping[i] = -1
	
	for n in range (faces.size()):
		var f = faces[n]
		for i in range (3):
			var ind = mdt.get_face_vertex(f, i)
			
			var new_ind = _FindOrAddUniqueVert(ind, unique_verts, ind_mapping)
			new_inds.push_back(new_ind)
		
			
	print ("mapping end")
			
	# create the new mesh
	var tmpMesh = Mesh.new()
	
	#print(orig_mi.get_name() + " orig mat count " + str(orig_mi.mesh.get_surface_count()))
	#var mat = orig_mi.get_surface_material(0)
	var mat = orig_mi.mesh.surface_get_material(0)
		
	#var mat = SpatialMaterial.new()
	#mat = mat_orig
	#var color = Color(0.1, 0.8, 0.1)
	#mat.albedo_color = color
	
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	#var xform = orig_mi.global_transform
	
	for u in unique_verts.size():
		var n = unique_verts[u]
		
		var vert = mdt.get_vertex(n)
		var norm = mdt.get_vertex_normal(n)
		var col = mdt.get_vertex_color(n)
		var uv = mdt.get_vertex_uv(n)
		var uv2 = mdt.get_vertex_uv2(n)
		var tang = mdt.get_vertex_tangent(n)

		vert = xform.xform(vert)
		norm = xform.basis.xform(norm)
		norm = norm.normalized()
		tang = xform.xform(tang)
		
		if norm:
			st.add_normal(norm)
		if col:
			st.add_color(col)
		if uv:
			st.add_uv(uv)
		if uv2:
			st.add_uv2(uv2)
		if tang:
			st.add_tangent(tang)
				
		st.add_vertex(vert)

	# indices
	for i in new_inds.size():
		st.add_index(new_inds[i])
		
	#print ("commit start")

	st.commit(tmpMesh)

	var new_mi = MeshInstance.new()
	new_mi.mesh = tmpMesh
	
	new_mi.set_surface_material(0, mat)
	
	new_mi.set_name(orig_mi.get_name() + "_" + str(grid_x) + str(grid_z))
	
	# add the new mesh as a child
	attachment_node.add_child(new_mi)
	pass
	
	
	
func _FindOrAddUniqueVert(orig_index : int, unique_verts, ind_mapping):
	if ind_mapping[orig_index] != -1:
		return ind_mapping[orig_index]
	
#	for n in range(unique_verts.size()):
#		if unique_verts[n] == orig_index:
#			return n
			
	# else add
	var new_index = unique_verts.size()
	unique_verts.push_back(orig_index)
	
	ind_mapping[orig_index] = new_index
	
	return new_index
	

func split_by_surface(orig_mi : MeshInstance, attachment_node : Node):
	var count = orig_mi.mesh.get_surface_count()
	if count <= 1:
		return # nothing to do
	
	# not used	
	var aabb = orig_mi.get_aabb()
	
	var mesh = orig_mi.mesh


	
	for s in range (count):
		var mdt = MeshDataTool.new()
		mdt.create_from_surface(mesh, s)
		
		var nVerts = mdt.get_vertex_count()
		if nVerts == 0:
			continue
			
		_split_mesh_by_surface(mdt, orig_mi, attachment_node, s)

	# delete orig mesh
	orig_mi.get_parent().remove_child(orig_mi)
	#orig_mi.queue_delete()
	
	pass



func _split_mesh_by_surface(mdt : MeshDataTool, orig_mi : MeshInstance, attachment_node : Node, surf_id : int):
	var nVerts = mdt.get_vertex_count()
	var nFaces = mdt.get_face_count()
	
	# create the new mesh
	var tmpMesh = Mesh.new()
	
	var mat = orig_mi.mesh.surface_get_material(surf_id)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	var xform = orig_mi.global_transform
	
	for n in mdt.get_vertex_count():
		var vert = mdt.get_vertex(n)
		var norm = mdt.get_vertex_normal(n)
		var col = mdt.get_vertex_color(n)
		var uv = mdt.get_vertex_uv(n)
		var uv2 = mdt.get_vertex_uv2(n)
		var tang = mdt.get_vertex_tangent(n)

		vert = xform.xform(vert)
		norm = xform.basis.xform(norm)
		norm = norm.normalized()
		tang = xform.xform(tang)
		
		if norm:
			st.add_normal(norm)
		if col:
			st.add_color(col)
		if uv:
			st.add_uv(uv)
		if uv2:
			st.add_uv2(uv2)
		if tang:
			st.add_tangent(tang)
		st.add_vertex(vert)

	# indices
	for f in mdt.get_face_count():
		for i in range (3):
			var ind = mdt.get_face_vertex(f, i)
			st.add_index(ind)

	st.commit(tmpMesh)

	var new_mi = MeshInstance.new()
	new_mi.mesh = tmpMesh
	
	new_mi.set_surface_material(0, mat)
	
	#new_mi.transform = orig_mi.transform
	
	var sz = orig_mi.get_name() + "_" + str(surf_id)
	if mat.resource_name != "":
		sz += "_" + mat.resource_name
	new_mi.set_name(sz)
	
	# add the new mesh as a child
	attachment_node.add_child(new_mi)
	pass

