# godot-splerger
Mesh splitting and merging script for Godot 3.1 / 3.2

## Instructions
All functionality is inside the Sperger class. You must create a splerger object before doing anything else:
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
