package a3dparticle.animators 
{
	import a3dparticle.animators.actions.ActionBase;
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.animators.actions.TimeAction;
	import a3dparticle.core.SimpleParticlePass;
	import a3dparticle.core.SubContainer;
	import away3d.animators.data.AnimationBase;
	import away3d.animators.data.AnimationStateBase;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimation extends AnimationBase
	{
		
		private var _hasGen:Boolean;
		
		private var _AGALVertexCode:String;
		private var _AGALFragmentCode:String;
		
		public var shaderRegisterCache:ShaderRegisterCache;
		
		private var _particleActions:Vector.<ActionBase>=new Vector.<ActionBase>();
		
		//dependent and global action
		private var timeAction:TimeAction;
		
		//set if it need to share velocity in other actions
		public var needVelocity:Boolean;
		
		public var needVelocityInFragment:Boolean;
		
		public var needCameraPosition:Boolean;
		
		public var needUV:Boolean;
		
		
		//vertex
		public var timeConst:ShaderRegisterElement;
		public var positionAttribute:ShaderRegisterElement;
		public var uvAttribute:ShaderRegisterElement;
		public var offestTarget:ShaderRegisterElement;
		public var scaleAndRotateTarget:ShaderRegisterElement
		public var velocityTarget:ShaderRegisterElement;
		public var vertexTime:ShaderRegisterElement;
		public var vertexLife:ShaderRegisterElement;
		public var zeroConst:ShaderRegisterElement;
		public var piConst:ShaderRegisterElement;
		public var OneConst:ShaderRegisterElement;
		public var TwoConst:ShaderRegisterElement;
		public var cameraPosConst:ShaderRegisterElement;
		//vary
		private var varyTime:ShaderRegisterElement;
		public var fragmentTime:ShaderRegisterElement;
		public var fragmentLife:ShaderRegisterElement;
		public var fragmentVelocity:ShaderRegisterElement;
		//fragment
		public var colorTarget:ShaderRegisterElement;
		public var colorDefalut:ShaderRegisterElement;
		public var textSample:ShaderRegisterElement;
		public var uvVar:ShaderRegisterElement;
		public var fragmentZeroConst:ShaderRegisterElement;
		public var fragmentPiConst:ShaderRegisterElement;
		public var fragmentOneConst:ShaderRegisterElement;
		
		
		public function ParticleAnimation()
		{
			super();
			
			timeAction = new TimeAction();
			timeAction.animation = this;
			addAction(timeAction);
			
		}
		
		public function get hasGen():Boolean
		{
			return _hasGen;
		}
		
		public function startGen():void
		{
			//_particleActions = _particleActions.sort(sortFn);
		}
		/*private function sortFn(action1:ActionBase, action2:ActionBase):Number
		{
			if (action1.priority > action2.priority) return 1;
			else return -1;
		}*/
		
		public function finishGen():void
		{
			_hasGen = true;
		}
		
		public function set startTimeFun(fun:Function):void
		{
			timeAction.startTimeFun = fun;
		}
		
		public function set endTimeFun(fun:Function):void
		{
			timeAction.endTimeFun = fun;
		}
		
		public function set sleepTimeFun(fun:Function):void
		{
			timeAction.loop = true;
			timeAction.sleepTimeFun = fun;
		}
		
		public function set loop(value:Boolean):void
		{
			timeAction.loop = value;
		}
		
		public function addAction(action:ActionBase):void
		{
			var i:int;
			for (i = _particleActions.length - 1; i >= 0; i--)
			{
				if (_particleActions[i].priority <= action.priority)
				{
					break;
				}
			}
			_particleActions.splice(i + 1, 0, action);
			action.animation = this;
		}
		
		public function genOne(index:uint):void
		{
			for each (var action:ActionBase in _particleActions)
			{
				if (action is PerParticleAction)
				{
					PerParticleAction(action).genOne(index);
				}
			}
		}
		
		public function distributeOne(index:uint, verticeIndex:uint, subContainer:SubContainer):void
		{
			for each (var action:ActionBase in _particleActions)
			{
				if (action is PerParticleAction)
				{
					PerParticleAction(action).distributeOne(index, verticeIndex, subContainer);
				}
			}
		}
		
		
		public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			//set some const
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, zeroConst.index, Vector.<Number>([ 0, 0, 0, 0 ]));
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, fragmentZeroConst.index, Vector.<Number>([ 0, 0, 0, 0 ]));
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, piConst.index, Vector.<Number>([ Math.PI * 2, Math.PI * 2, Math.PI * 2, Math.PI * 2 ]));
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, OneConst.index, Vector.<Number>([ 1, 1, 1, 1 ]));
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, TwoConst.index, Vector.<Number>([ 2, 2, 2, 2 ]));
			
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, fragmentPiConst.index, Vector.<Number>([ Math.PI * 2, Math.PI * 2, Math.PI * 2, Math.PI * 2 ]));
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, fragmentOneConst.index, Vector.<Number>([ 1, 1, 1, 1 ]));
			
			
			var action:ActionBase;
			for each(action in _particleActions)
			{
				action.setRenderState(stage3DProxy,pass,renderable);
			}
		}
		
		public function render():void
		{
			
		}
		
		
		private function reset(simpleParticlePass:SimpleParticlePass):void
		{
			shaderRegisterCache = new ShaderRegisterCache();
			shaderRegisterCache.vertexConstantOffset = 4;
			shaderRegisterCache.vertexAttributesOffset = 1;
			shaderRegisterCache.reset();
			
			//because of projectionVertexCode,I set these value directly
			scaleAndRotateTarget = new ShaderRegisterElement("vt", 0);
			shaderRegisterCache.addVertexTempUsages(scaleAndRotateTarget, 1);
			scaleAndRotateTarget = new ShaderRegisterElement(scaleAndRotateTarget.regName, scaleAndRotateTarget.index, "xyz");//only use xyz, w is used as vertexLife
			positionAttribute = new ShaderRegisterElement("va", 0);
			//allot const register
			timeConst = shaderRegisterCache.getFreeVertexConstant();
			zeroConst = shaderRegisterCache.getFreeVertexConstant();
			piConst = shaderRegisterCache.getFreeVertexConstant();
			OneConst = shaderRegisterCache.getFreeVertexConstant();
			TwoConst = shaderRegisterCache.getFreeVertexConstant();
			if (needCameraPosition) cameraPosConst = shaderRegisterCache.getFreeVertexConstant();
			
			colorDefalut = shaderRegisterCache.getFreeFragmentConstant();
			fragmentZeroConst = shaderRegisterCache.getFreeFragmentConstant();
			fragmentPiConst = shaderRegisterCache.getFreeFragmentConstant();
			fragmentOneConst = shaderRegisterCache.getFreeFragmentConstant();
			//allot attribute register
			if (needUV)
			{
				uvAttribute = shaderRegisterCache.getFreeVertexAttribute();
			}
			//allot temp register
			var tempTime:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			offestTarget = new ShaderRegisterElement(tempTime.regName, tempTime.index, "xyz");
			shaderRegisterCache.addVertexTempUsages(tempTime, 1);
			vertexTime = new ShaderRegisterElement(tempTime.regName, tempTime.index, "w");
			vertexLife = new ShaderRegisterElement(scaleAndRotateTarget.regName, scaleAndRotateTarget.index, "w");
			if (needVelocity)
			{
				velocityTarget = shaderRegisterCache.getFreeVertexVectorTemp();
				shaderRegisterCache.addVertexTempUsages(velocityTarget, 1);
			}
			
			colorTarget = shaderRegisterCache.getFreeFragmentVectorTemp();
			shaderRegisterCache.addFragmentTempUsages(colorTarget,1);
			
			//allot vary register
			varyTime = shaderRegisterCache.getFreeVarying();
			fragmentTime = new ShaderRegisterElement(varyTime.regName, varyTime.index, "x");
			fragmentLife = new ShaderRegisterElement(varyTime.regName, varyTime.index, "y");
			fragmentVelocity = new ShaderRegisterElement(varyTime.regName, varyTime.index, "z");
			if (needUV)
			{
				uvVar = shaderRegisterCache.getFreeVarying();
			}
			//allot fs register
			textSample = shaderRegisterCache.getFreeTextureReg();
		}
		/**
		 * @inheritDoc
		 */
		override arcane function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var simpleParticlePass:SimpleParticlePass = SimpleParticlePass(pass);
			reset(simpleParticlePass);
			
			_AGALVertexCode = "";
			if (needVelocity)
			{
				_AGALVertexCode += "mov " + velocityTarget.toString() + "," + zeroConst.toString() + "\n";
			}
			if (needUV)
			{
				_AGALVertexCode += "mov " + uvVar.toString() + "," + uvAttribute.toString() + "\n";
			}
			_AGALVertexCode += "mov " + varyTime.toString() + ".zw," + zeroConst.toString() + "\n";
			_AGALVertexCode += "mov " + offestTarget.toString() + "," + zeroConst.toString() + "\n";
			_AGALVertexCode += "mov " + scaleAndRotateTarget.toString() + "," + positionAttribute.toString() + "\n";
			var action:ActionBase;
			for each(action in _particleActions)
			{
				_AGALVertexCode += action.getAGALVertexCode(pass);
			}
			if (needVelocity && needVelocityInFragment)
			{
				_AGALVertexCode += "dp3 " + velocityTarget.toString() + ".x," + velocityTarget.toString() + "," + velocityTarget.toString() + "\n";
				_AGALVertexCode += "sqt " + fragmentVelocity.toString() + "," + velocityTarget.toString() + ".x\n";
			}
			_AGALVertexCode += "add " + scaleAndRotateTarget.toString() +"," + scaleAndRotateTarget.toString() + "," + offestTarget.toString() + "\n";
			_AGALVertexCode += "mov " + scaleAndRotateTarget.regName +scaleAndRotateTarget.index.toString() + ".w," + OneConst.toString() + "\n";
			return _AGALVertexCode;
		}		
		
		arcane function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			_AGALFragmentCode = ""; 
			var action:ActionBase;
			for each(action in _particleActions)
			{
				_AGALFragmentCode += action.getAGALFragmentCode(pass);
			}
			return _AGALFragmentCode;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			//
			var i:int;0
			for (i = pass.numUsedStreams; i < shaderRegisterCache.numUsedStreams; i++)
			{
				stage3DProxy.setSimpleVertexBuffer(i, null);
			}
			super.deactivate(stage3DProxy , pass );
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function createAnimationState() : AnimationStateBase
		{
			return null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function equals(animation : AnimationBase) : Boolean
		{
			return animation == this;
		}
		
	}

}