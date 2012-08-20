package com.mightybits.asparse.net
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import org.osflash.signals.Signal;

	public class ServiceCall
	{
		private var _result:Function;
		private var _fail:Function;
		private var _args:Array;
		
		public function ServiceCall(request:URLRequest, result:Function, fail:Function = null, args:Array = null)
		{
			_result = result;
			_fail = fail;
			_args = args;
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.load(request);
		}
	
		protected function onComplete(event:Event):void
		{
			var result:String = URLLoader(event.target).data.toString();
			
			if(_args && _args.length > 0){
				_result(JSON.parse(result), _args);
			}else{
				_result(JSON.parse(result));
			}
			
		}
		
		protected function onIOError(event:IOErrorEvent):void
		{
			if(_fail != null) _fail();		
		}
	}
}