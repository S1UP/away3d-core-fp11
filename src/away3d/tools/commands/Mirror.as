package away3d.tools.commands
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	import away3d.tools.helpers.MeshHelper;
	import away3d.tools.utils.Bounds;
	
	import flash.geom.Vector3D;
	use namespace arcane;
	
	public class Mirror
	{
		public static const X_AXIS:String = "x";
		public static const MAX_BOUND_X:String = "x+";
		public static const MIN_BOUND_X:String = "x-";
		
		public static const Y_AXIS:String = "y";
		public static const MAX_BOUND_Y:String = "y+";
		public static const MIN_BOUND_Y:String = "y-";
		
		public static const Z_AXIS:String = "z";
		public static const MAX_BOUND_Z:String = "z+";
		public static const MIN_BOUND_Z:String = "z-";
		
		private static const LIMIT:uint = 196605;
		
		private static var _axes:Array = [	X_AXIS, MAX_BOUND_X, MIN_BOUND_X,
														Y_AXIS, MAX_BOUND_Y, MIN_BOUND_Y,
														Z_AXIS, MAX_BOUND_Z, MIN_BOUND_Z];
		
		 
		/*
		* Mirrors one or more Geometry objects found into an ObjectContainer.
		* 
		* @param	 obj			The ObjectContainer3D to be mirrored
		* @param	 axis			The axis to mirror around. A string X_AXIS ("x"), MAX_BOUND_X ("x+"), MIN_BOUND_X ("x-"), Y_AXIS ("y"), MAX_BOUND_Y ("y+"), MIN_BOUND_Y ("y-"), Z_AXIS ("z"), MAX_BOUND_Z ("z+"), MIN_BOUND_Z ("z-"). 
		* @param	 recenter	[optional]	Recenter the geometry. Applies only to meshes with geometries. Default is false.
		* @param	 duplicate	[optional]	Duplicate the model geometry along a given axis or simply mirrors the geometry. Default is true.
		*/
		
		public static function apply(obj:ObjectContainer3D, axis:String, recenter:Boolean = false, duplicate:Boolean = true):void
		{
			axis = axis.toLowerCase();
			 
			if(Mirror.validate(axis)){
				
				var child:ObjectContainer3D;
				
				if(obj is Mesh &&  obj.numChildren == 0 && Mesh(obj).geometry)
					Mirror.build( Mesh(obj), axis, recenter, duplicate);
					 
				for(var i:uint = 0;i<obj.numChildren;++i){
					child = ObjectContainer3D(obj).getChildAt(i);
					Mirror.apply(child, axis, recenter, duplicate);
				}
				 
			} else {
				throw new Error("Invalid axis parameter: "+Mirror._axes.toString());
			}
		}
		 
		private static function validate( axis:String):Boolean
		{
			for(var i:int =0;i<Mirror._axes.length;++i)
				if(axis == Mirror._axes[i]) return true;
				
			return false;
		}
		
		private static function getNextAvailableSubGeometry(index:uint, vectors:Array, materials:Vector.<MaterialBase>):int
		{ 
			var mat:MaterialBase = materials[index];
			var i:uint = (index*5)+5;
			var len:uint = vectors.length;
			if(i > len) return -1;
			
			for (i; i<len; i+=5)
				if(mat == materials[i/5] && Vector.<uint>(vectors[i+1]).length < LIMIT) return i;
			
			return -1;
		}
		
		private static function buildVector(len:uint):Vector.<Number>
		{ 
			var v:Vector.<Number> = new Vector.<Number>();
			var i:uint;
			while (i < len) v[i++] = 0.0;
			return v;
		}
		 
		private static function build(mesh:Mesh, axis:String, recenter:Boolean, duplicate:Boolean = true):void
		{ 
				if(duplicate && (mesh.rotationX != 0 || mesh.rotationY != 0 || mesh.rotationZ != 0) ) 
					MeshHelper.applyRotations(mesh);
				 
				Bounds.getMeshBounds(mesh);
				var minX:Number = Bounds.minX;
				var minY:Number = Bounds.minY;
				var minZ:Number = Bounds.minZ;
				var maxX:Number = Bounds.maxX;
				var maxY:Number = Bounds.maxY;
				var maxZ:Number = Bounds.maxZ;
				
				var offset:Number;
				var doubleOffset:Number;
				var posi:Vector3D = mesh.position;
				
				switch(axis){
					
						case  X_AXIS:
							offset = posi.x / mesh.scaleX;
							doubleOffset = offset*2;
							break;
						case MIN_BOUND_X:
						case MAX_BOUND_X:
							offset = Math.abs(minX)+maxX;
							offset /= mesh.scaleX;
							break;
						
						case Y_AXIS:
							offset = posi.y / mesh.scaleY;
							doubleOffset = offset*2;
							break;
						case MIN_BOUND_Y:
						case MAX_BOUND_Y:
							offset =   Math.abs(maxY)+maxY;
							offset /= mesh.scaleY;
							break;
						
						case Z_AXIS:
							offset = posi.z / mesh.scaleZ;
							doubleOffset = offset*2;
							break;
						case MIN_BOUND_Z:
						case MAX_BOUND_Z:
							offset = Math.abs(minZ)+maxZ;
							offset /= mesh.scaleZ;
							
				}
			 
				var geometry:Geometry = mesh.geometry;
				var geometries:Vector.<SubGeometry> = geometry.subGeometries;
				var numSubGeoms:uint = geometries.length;
				
				if(duplicate){
					var materials:Vector.<MaterialBase> = new Vector.<MaterialBase>();
					for (i = 0; i<mesh.subMeshes.length; ++i)
						materials.push(mesh.subMeshes[i].material);
						
					var matCount:uint = materials.length;
				}
				
				var sourceVerts:Vector.<Number>;
				var sourceIndices:Vector.<uint>;
				var sourceUVs:Vector.<Number>;
				var sourceNormals:Vector.<Number>;
				var sourceTangents:Vector.<Number>;
				
				var x:Number;
				var y:Number;
				var z:Number;
				var u:Number;
				var v:Number;
				var nx:Number;
				var ny:Number;
				var nz:Number;
				var tx:Number;
				var ty:Number;
				var tz:Number;
				
				var i:uint;
				var j:uint;
				var vectors:Array = [];
				var sub_geom:SubGeometry;
				 
				 for (i = 0; i<numSubGeoms; ++i){					 
					 
					sub_geom = geometries[i];
					sourceVerts = sub_geom.vertexData;
					sourceIndices = sub_geom.indexData;
					sourceUVs = sub_geom.UVData;

					try{
						sourceNormals = sub_geom.vertexNormalData;
						if(sourceNormals){
							sub_geom.autoDeriveVertexNormals = false;
						} else{
							sourceNormals = buildVector(sourceVerts.length);
							sub_geom.autoDeriveVertexNormals = true;
						}
					} catch(e:Error) {
						sub_geom.autoDeriveVertexNormals = true;
						sourceNormals = buildVector(sourceVerts.length);
					}
					
					try{
						sourceTangents = sub_geom.vertexTangentData;
						if(sourceTangents){
							sub_geom.autoDeriveVertexTangents = false;
						} else{
							sourceTangents = buildVector(sourceVerts.length);
							sub_geom.autoDeriveVertexTangents = true;
						}
					} catch(e:Error) {
						sub_geom.autoDeriveVertexTangents = true;
						sourceTangents = buildVector(sourceVerts.length);
					}
					 
					sourceVerts.fixed = false;
					sourceIndices.fixed = false;
					sourceUVs.fixed = false;
					sourceNormals.fixed = false;
					sourceTangents.fixed = false;
					 
					vectors.push(sourceVerts, sourceIndices, sourceUVs, sourceNormals, sourceTangents);
				} 
				 
				var destverts:Vector.<Number> = vectors[0];
				var destindices:Vector.<uint> = vectors[1];
				var destuvs:Vector.<Number> = vectors[2];
				var destnormals:Vector.<Number> = vectors[3];
				var desttangents:Vector.<Number> = vectors[4];
				
				var indexVector:uint;
				var isFace:int = 0;
				var val:Number;
				var indLoop:uint;
				var destIndV:uint;
				var destIndUV:uint;
				var xindex:uint;
				var xindex1:uint;
				var xindex2:uint;
				var uindex:uint;
				var uindex1:uint;
				var ind:uint;
				var nextID:int;
				
				for (i = 0; i<numSubGeoms; ++i){
					 
					indexVector = i*5;
					sourceVerts = vectors[indexVector];
					sourceIndices = vectors[indexVector+1];
					sourceUVs = vectors[indexVector+2];
					sourceNormals = vectors[indexVector+3];
					sourceTangents = vectors[indexVector+4];
					
					/*if(duplicate || (i > 0 && materials[i] != materials[i-1])){
						destverts = sourceVerts;
						destindices = sourceIndices;
						destuvs = sourceUVs;
						destnormals = sourceNormals;
						desttangents = sourceTangents;
					}*/
						
					indLoop = sourceIndices.length;
					for (j = 0; j<indLoop; ++j){
						
						xindex = sourceIndices[j]*3;
						uindex = sourceIndices[j]<<1;
						
						if(duplicate){
							
							if(destverts.length == LIMIT){
								isFace = 0;
								
								if(i != materials.length-1) nextID = getNextAvailableSubGeometry(i, vectors, materials);
								
								if(materials.length == 1 || nextID == -1){
									destverts = new Vector.<Number>();
									destindices = new Vector.<uint>();
									destuvs = new Vector.<Number>();
									destnormals = new Vector.<Number>();
									desttangents = new Vector.<Number>();
									vectors.push(destverts,destindices,destuvs,destnormals,desttangents);
									sub_geom = new SubGeometry();
									geometry.addSubGeometry(sub_geom);
									materials.push(materials[i]);
									matCount++;
								} else {
									destverts = vectors[nextID];
									destindices = vectors[nextID+1];
									destuvs = vectors[nextID+2];
									destnormals = vectors[nextID+3];
									desttangents = vectors[nextID+4];
								}
							}
							
							isFace++;
							
							 
							destindices.push(destverts.length/3);
							destuvs.push(sourceUVs[uindex], sourceUVs[uindex+1]);
							destnormals.push(sourceNormals[xindex], sourceNormals[xindex+1], sourceNormals[xindex+2]);
							desttangents.push(sourceTangents[xindex],sourceTangents[xindex+1],sourceTangents[xindex+2]);
							
							switch(axis){
								 
								case X_AXIS:
									val = (offset>0)? -sourceVerts[xindex] - doubleOffset : -sourceVerts[xindex] + -doubleOffset;
									if(recenter){
										if(val > maxX) maxX = val;
										if(val< minX) minX = val;
									}
									destverts.push( val, sourceVerts[xindex+1], sourceVerts[xindex+2]);
									destnormals[destnormals.length-3] *=-1;
									desttangents[desttangents.length-3] *=-1;
									break;
									
								case MIN_BOUND_X:
									val = -sourceVerts[xindex] - offset;
									if(recenter && val< minX) minX = val;
									destverts.push( val, sourceVerts[xindex+1], sourceVerts[xindex+2]);
									destnormals[destnormals.length-3] *=-1;
									desttangents[desttangents.length-3] *=-1;
									break;
									
								case MAX_BOUND_X:
									val = -sourceVerts[xindex] + offset;
									if(recenter && val> maxX) maxX = val;
									destverts.push(val, sourceVerts[xindex+1], sourceVerts[xindex+2]);
									destnormals[destnormals.length-3] *=-1;
									desttangents[desttangents.length-3] *=-1;
									break;
								
								
								
								case Y_AXIS:
									val = (offset>0)? -sourceVerts[xindex+1] - doubleOffset : -sourceVerts[xindex+1] + -doubleOffset;
									if(recenter){
										if(val > maxY) maxY = val;
										if(val< minY) minY = val;
									}
									destverts.push( sourceVerts[xindex], val, sourceVerts[xindex+2]);
									destnormals[destnormals.length-2] *=-1;
									desttangents[desttangents.length-2] *=-1;
									break;
									
								case MIN_BOUND_Y:
									val = -sourceVerts[xindex+1] - offset;
									if(recenter && val< minY) minY = val;
									destverts.push( sourceVerts[xindex], val, sourceVerts[xindex+2]);
									destnormals[destnormals.length-2] *=-1;
									desttangents[desttangents.length-2] *=-1;
									break;
									
								case MAX_BOUND_Y:
									val = -sourceVerts[xindex+1] + offset;
									if(recenter && val> maxY) maxY = val;
									destverts.push( sourceVerts[xindex], val, sourceVerts[xindex+2]);
									destnormals[destnormals.length-2] *=-1;
									desttangents[desttangents.length-2] *=-1;
									break;
								
								
								
								case Z_AXIS:
									val = (offset>0)? -sourceVerts[xindex+2] - doubleOffset : -sourceVerts[xindex+2] + -doubleOffset;
									if(recenter){
										if(val > maxZ) maxZ = val;
										if(val< minZ) minZ = val;
									}
									destverts.push( sourceVerts[xindex], sourceVerts[xindex+1], val);
									destnormals[destnormals.length-1] *=-1;
									desttangents[desttangents.length-1] *=-1;
									break;
									
								case MIN_BOUND_Z:
									val = -sourceVerts[xindex+2] - offset;
									if(recenter && val< minZ) minZ = val;
									destverts.push( sourceVerts[xindex], sourceVerts[xindex+1], val);
									destnormals[destnormals.length-1] *=-1;
									desttangents[desttangents.length-1] *=-1;
									break;
									
								case MAX_BOUND_Z:
									val = -sourceVerts[xindex+2] - offset;
									if(recenter && val > maxZ) maxZ = val;
									destverts.push( sourceVerts[xindex], sourceVerts[xindex+1], val);
									destnormals[destnormals.length-1] *=-1;
									desttangents[desttangents.length-1] *=-1;
									 
							}
							
							
							if(isFace == 3){
								isFace = 0;
								
								destIndV = destverts.length;
								destIndUV = destuvs.length;
								
								u = destuvs[destIndUV-2];
								v = destuvs[destIndUV-1];
								
								destuvs[destIndUV-2] = destuvs[destIndUV-4];
								destuvs[destIndUV-1] = destuvs[destIndUV-3];
								
								destuvs[destIndUV-4] = u;
								destuvs[destIndUV-3] = v;
								 
								x = destverts[destIndV-3];
								y = destverts[destIndV-2];
								z = destverts[destIndV-1];
								
								nx = destnormals[destIndV-3];
								ny = destnormals[destIndV-2];
								nz = destnormals[destIndV-1];
								
								tx = desttangents[destIndV-3];
								ty = desttangents[destIndV-2];
								tz = desttangents[destIndV-1]; 
								
								destverts[destIndV-3] = destverts[destIndV-6];
								destverts[destIndV-2] = destverts[destIndV-5];
								destverts[destIndV-1] = destverts[destIndV-4];
								
								destnormals[destIndV-3] = destnormals[destIndV-6];
								destnormals[destIndV-2] = destnormals[destIndV-5];
								destnormals[destIndV-1] = destnormals[destIndV-4];
								
								desttangents[destIndV-3] = desttangents[destIndV-6];
								desttangents[destIndV-2] = desttangents[destIndV-5];
								desttangents[destIndV-1] = desttangents[destIndV-4];
								
								destverts[destIndV-6] = x;
								destverts[destIndV-5] = y;
								destverts[destIndV-4] = z;
								
								destnormals[destIndV-6] = nx;
								destnormals[destIndV-5] = ny;
								destnormals[destIndV-4] = nz;
								
								desttangents[destIndV-6] = tx;
								desttangents[destIndV-5] = ty;
								desttangents[destIndV-4] = tz;
								 
							}  
							 
						} else {
							 
							  switch(axis){
								
								case X_AXIS:
									sourceVerts[xindex] = -sourceVerts[xindex] - doubleOffset;
									sourceNormals[xindex] *=-1;
									sourceTangents[xindex] *=-1;
									break;
								case MIN_BOUND_X:
									sourceVerts[xindex] = -sourceVerts[xindex] - offset;
									sourceNormals[xindex] *=-1;
									sourceTangents[xindex] *=-1;
									break;
								case MAX_BOUND_X:
									sourceVerts[xindex] = -sourceVerts[xindex] + offset;
									sourceNormals[xindex] *=-1;
									sourceTangents[xindex] *=-1;
									break;
								
								case Y_AXIS:
									sourceVerts[xindex+1] = -sourceVerts[xindex+1] - doubleOffset;
									sourceNormals[xindex+1] *=-1;
									sourceTangents[xindex+1] *=-1;
									break;
								case MIN_BOUND_Y:
									sourceVerts[xindex+1] = -sourceVerts[xindex+1] - offset;
									sourceNormals[xindex+1] *=-1;
									sourceTangents[xindex+1] *=-1;
									break;
								
								case MAX_BOUND_Y:
									sourceVerts[xindex+1] = -sourceVerts[xindex+1] + offset;
									sourceNormals[xindex+1] *=-1;
									sourceTangents[xindex+1] *=-1;
									break;
								 
								case Z_AXIS:
									sourceVerts[xindex+2] = -sourceVerts[xindex+2] - doubleOffset;
									sourceNormals[xindex+2] *=-1;
									sourceTangents[xindex+2] *=-1;
									break;
								
								case MIN_BOUND_Z:
									sourceVerts[xindex+2] = -sourceVerts[xindex+2] - offset;
									sourceNormals[xindex+2] *=-1;
									sourceTangents[xindex+2] *=-1;
									break;
								
								case MAX_BOUND_Z:
									sourceVerts[xindex+2] = -sourceVerts[xindex+2] + offset;
									sourceNormals[xindex+2] *=-1;
									sourceTangents[xindex+2] *=-1;
							} 
							
							
							if(isFace == 3){
								isFace = 0;
								 
								xindex1 = sourceIndices[j-1]*3;
								xindex2 = sourceIndices[j-2]*3;
								 
								uindex = sourceIndices[j-1]<<1;
								uindex1 = sourceIndices[j-2]<<1;
								 
								x = sourceVerts[xindex1];
								y = sourceVerts[xindex1+1];
								z = sourceVerts[xindex1+2];
								
								nx = sourceNormals[xindex1];
								ny = sourceNormals[xindex1+1];
								nz = sourceNormals[xindex1+2];
								 
								tx = sourceTangents[xindex1];
								ty = sourceTangents[xindex1+1];
								tz = sourceTangents[xindex1+2];
								
								sourceVerts[xindex1] = sourceVerts[xindex2];
								sourceVerts[xindex1+1] = sourceVerts[xindex2+1];
								sourceVerts[xindex1+2] = sourceVerts[xindex2+2];
								
								sourceNormals[xindex1] = sourceNormals[xindex2];
								sourceNormals[xindex1+1] = sourceNormals[xindex2+1];
								sourceNormals[xindex1+2] = sourceNormals[xindex2+2];
								
								sourceTangents[xindex1] = sourceTangents[xindex2];
								sourceTangents[xindex1+1] = sourceTangents[xindex2+1];
								sourceTangents[xindex1+2] = sourceTangents[xindex2+2];
								
								sourceVerts[xindex2] = x;
								sourceVerts[xindex2+1] = y;
								sourceVerts[xindex2+2] = z;
								
								sourceNormals[xindex2] = nx;
								sourceNormals[xindex2+1] = ny;
								sourceNormals[xindex2+2] = nz;
								
								sourceTangents[xindex2] = tx;
								sourceTangents[xindex2+1] = ty;
								sourceTangents[xindex2+2] = tz;
								
								u = sourceUVs[uindex];
								v = sourceUVs[uindex+1];
								
								sourceUVs[uindex] = sourceUVs[uindex1];
								sourceUVs[uindex+1] = sourceUVs[uindex1+1];
								
								sourceUVs[uindex1] = u;
								sourceUVs[uindex1+1] = v;
							} 
							 
						} 
						
					}
				}
			
			geometries = geometry.subGeometries;
			numSubGeoms = geometries.length;
			
			for (i = 0; i<numSubGeoms; ++i){
				indexVector = i*5;
				sub_geom = SubGeometry(geometry.subGeometries[i]);
				sub_geom.updateVertexData(vectors[indexVector]);
				sub_geom.updateUVData(vectors[indexVector+2]);
				
				if(duplicate){
					sub_geom.updateIndexData(vectors[indexVector+1]);
					
				} else {
					sourceIndices = vectors[indexVector+1];
					indLoop = sourceIndices.length;
					for (j = 0; j<indLoop; j+=3){
						ind = sourceIndices[j];
						sourceIndices[j] = sourceIndices[j+1];
						sourceIndices[j+1] = ind;
					}
					sub_geom.updateIndexData(sourceIndices);
				}
				
				sub_geom.updateVertexNormalData(vectors[indexVector+3]);
				sub_geom.updateVertexTangentData(vectors[indexVector+4]);
			}
			
			vectors = null;
			 
			if(duplicate){
				var matind:uint = 0;
				for (i = matCount; i<mesh.subMeshes.length; ++i){
					if(MaterialBase(materials[matind]) != null)
						mesh.subMeshes[i].material = materials[matind];
						
					matind++;
				}
			}

			if(recenter)
				MeshHelper.applyPosition(mesh, (minX+maxX)*.5, (minY+maxY)*.5, (minZ+maxZ)*.5);
			
		}
		
	}
}