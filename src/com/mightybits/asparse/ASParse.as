package com.mightybits.asparse
{

	import com.mightybits.asparse.net.ParseObject;
	import com.mightybits.asparse.net.ServiceCall;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.getClassByAlias;
	import flash.utils.getDefinitionByName;
	
	import org.osflash.signals.Signal;
	
	public class ASParse
	{
		public static const REST_HEADER_NAME_APP_ID:String = "X-Parse-Application-Id";
		public static const REST_HEADER_NAME_API_KEY:String = "X-Parse-REST-API-Key";
		public static const REST_HEADER_NAME_SESSION_TOKEN:String = "X-Parse-Session-Token";
		
		// API URLs 
		public static const PARSE_API_CLASS:String = "https://api.parse.com/1/classes/";
		public static const PARSE_API_USER:String = "https://api.parse.com/1/users";
		public static const PARSE_API_ROLES:String = "https://api.parse.com/1/roles";
		public static const PARSE_API_FILES:String = "https://api.parse.com/1/files";
		public static const PARSE_API_PUSH:String = "https://api.parse.com/1/push";
		
		// Signals
		public var onCount:Signal = new Signal(Number);
		public var onCreate:Signal = new Signal(ParseObject);
		public var onRead:Signal = new Signal(Object);
		public var onRemove:Signal = new Signal();
		public var onSearch:Signal = new Signal(Array);
		public var onUpdate:Signal = new Signal(Object);
		
		public var onServiceFail:Signal = new Signal();
		
		// headers
		private var app_key:String;
		private var rest_key:String;
		private var session_token:String;
		
		
		public function ASParse( app_key:String, rest_key:String )
		{
			super();
			
			this.app_key = app_key;
			this.rest_key = rest_key;
		}
		
		//  PUBLIC FUNCTIONS
		// -----------------------------------------------------------------//
		
		public function count( ClassRef:Class, where:String = null, count:Number = 1, limit:Number = 0 ):void
		{	
			var obj:ParseObject = new ClassRef();
			var query:URLVariables = new URLVariables();			
			query.count = count;
			query.limit = limit;			
			
			if( where != null )
			{
				query.where = JSON.stringify(where)
			}
			
			var request:URLRequest = getClassRequest(obj.getClassName(), URLRequestMethod.GET);
			request.data = query;					
			
			load(request, onCountComplete);
		}
		
		public function create( value:ParseObject ):void
		{		
			var request:URLRequest = getClassRequest(value.getClassName(), URLRequestMethod.POST);
			request.data = JSON.stringify( value );
			
			load(request, onCreateComplete, value);		
		}
		
		public function read( ClassRef:Class, objectId:String ):void
		{
			var obj:ParseObject = new ClassRef();
			var request:URLRequest = getClassRequest(obj.getClassName() + "/" + objectId, URLRequestMethod.GET);
			
			load(request, onReadComplete);		
		}		
		
		public function remove( ClassRef:Class, objectId:String ):void
		{
			var obj:ParseObject = new ClassRef();
			var request:URLRequest = getClassRequest(obj.getClassName() + "/" + objectId, URLRequestMethod.DELETE);
				
			load(request, onRemoveComplete);		
		}				
		
		public function search( ClassRef:Class, where:Object = null, limit:Number = 100, skip:Number = 0 ):void
		{
			var obj:ParseObject = new ClassRef();
			
			var query:URLVariables = new URLVariables();
			query.limit = limit;
			query.skip = skip;
			
			if( where != null )
			{
				query.where = JSON.stringify( where );
			}
			
			var request:URLRequest = getClassRequest(obj.getClassName(), URLRequestMethod.GET);
			request.data = query;				
			
			load(request, onSearchComplete);			
		}						
		
		public function update( value:ParseObject, change:Object ):void
		{
			var request:URLRequest = getClassRequest(value.getClassName() + "/" + value.objectId, URLRequestMethod.PUT);
			request.data = JSON.stringify( change );
			
			load(request, onUpdateComplete, value);
		}	
		
		//  PRIVATE FUNCTIONS
		// -----------------------------------------------------------------//
	
		private function load(request:URLRequest, resultHandler:Function, ...args):void
		{
			new ServiceCall(request, resultHandler, onServiceFailed, args);
		}	
		
		//  HANDLER FUNCTIONS
		// -----------------------------------------------------------------//
		
		protected function onServiceFailed():void
		{
			onServiceFail.dispatch();	
		}
		
		protected function onCountComplete(result:Object):void
		{
			onCount.dispatch(result.count);
		}
		
		protected function onCreateComplete(result:Object, args:Array):void
		{
			var obj:ParseObject = args[0];
			obj.createdAt = result.createdAt;
			obj.objectId = result.objectId;
			
			onCreate.dispatch(obj);
		}
		
		protected function onReadComplete(result:Object):void
		{
			onRead.dispatch(result);
		}
		
		protected function onRemoveComplete(result:Object):void
		{
			onRemove.dispatch();
		}
		
		protected function onSearchComplete( result:Object ):void
		{	
			onSearch.dispatch(parseData(result.results));
		}
		
		protected function onUpdateComplete(result:Object, args:Array):void
		{
			var obj:ParseObject = args[0];
			obj.updatedAt = result.updatedAt;
			
			onUpdate.dispatch(obj);
		}
		
		private function parseData(data:*):*
		{
			if(data is Array)
			{
				var arr:Array = [];
				for each (var item:Object in data)
				{
					arr.push(parseObject(item));
				}	
				
				return arr;
			}
			else
			{
				return parseObject(data);
			}
		}	
		
		private function parseObject(data:Object):Object
		{
			if(data && data.qualifiedClassName)
			{
				var ClassRef:Class = getDefinitionByName(data.qualifiedClassName) as Class
				
				var result:Object = new ClassRef();
				for (var prop:String in data)
				{
					if(prop != "qualifiedClassName")
					{
						result[prop] = data[prop];
					}
				}	
				
				return result;
			}
			
			return data;
		}	
		
		protected function getClassRequest(service:String, method:String, contentType:String = "application/json"):URLRequest
		{
			var request:URLRequest = new URLRequest(PARSE_API_CLASS + service);
			request.requestHeaders.push( new URLRequestHeader(REST_HEADER_NAME_APP_ID , app_key ) );
			request.requestHeaders.push( new URLRequestHeader(REST_HEADER_NAME_API_KEY , rest_key ) );
			request.method = method;
			request.contentType = contentType;
			
			if(session_token && session_token != "")
				request.requestHeaders.push( new URLRequestHeader(REST_HEADER_NAME_SESSION_TOKEN , session_token ) );
			
			return request;
		}	
		
	}
}