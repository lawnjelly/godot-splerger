# godot-splerger
Mesh splitting and merging script for Godot 3.1 / 3.2

## Instructions
All functionality is inside the Splerger class. You must create a splerger object before doing anything else:
```
var splerger = Splerger.new()
```
## Merging
```
func merge_meshinstances(var mesh_array,
var attachment_node : Node,
var use_local_space : bool = false,
var delete_originals : bool = true):
```
* mesh_array is an array of MeshInstances to be merged
* attachment node is where you want the merged MeshInstance to be added
* use_local_space will not change the coordinate space of the meshes, however it assumes they all share the same local transform as the first mesh instance in the array
* delete_originals - determines whether the original mesh instances will be deleted

e.g.
```
	var splerger = Splerger.new()
	
	var mergelist = []
	mergelist.push_back($Level/Level/Sponza_15_roof_00)
	mergelist.push_back($Level/Level/Sponza_15_roof_10)
	mergelist.push_back($Level/Level/Sponza_15_roof_20)
	mergelist.push_back($Level/Level/Sponza_15_roof_30)
	mergelist.push_back($Level/Level/Sponza_15_roof_40)
	mergelist.push_back($Level/Level/Sponza_15_roof_50)
	mergelist.push_back($Level/Level/Sponza_15_roof_60)
	splerger.merge_meshinstances(mergelist, $Level)
```
## Splitting by Surface
If a MeshInstance contains more than one surface (material), you can split it into constituent meshes by surface.
```
func split_by_surface(orig_mi : MeshInstance,
attachment_node : Node,
use_local_space : bool = false):
```
## Splitting by Grid
Meshes that are large cannot be culled well, and will either by rendered in their entirety or not at all. Sometimes it is more efficient to split large meshes by their location. Splerger can do this automatically by applying a 3d grid, with a grid size specified for the x and z coordinates, and separately for the y coordinate (height).
```
func split(mesh_instance : MeshInstance,
grid_size : float,
grid_size_y : float,
attachment_node : Node,
use_local_space : bool = false,
delete_orig : bool = true):
```
## Splitting many meshes by Grid
You can also split multiple MeshInstance with one command:
```
func split_branch(node : Node,
grid_size : float,
grid_size_y : float = 0.0,
use_local_space : bool = false):
```
This will search recursively and find all the MeshInstances in the scene graph that are children / grandchildren of 'node', and perform a split by grid on them.

# Notes
Although this script will perform splitting and merging, it is recommended that you apply this as a preprocess and save the resulting MeshInstances for use in game. See here:

https://godotengine.org/qa/903/how-to-save-a-scene-at-run-time

For an explanation of how to save nodes / branches as scenes.
