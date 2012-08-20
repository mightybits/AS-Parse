package com.mightybits.asparse.net
{
	import flash.utils.getQualifiedClassName;

	dynamic public class ParseObject
	{
		public var objectId:String;
		public var createdAt:String;
		public var updatedAt:String;
		
		public function get qualifiedClassName():String
		{
			return getQualifiedClassName(this).replace(/::/g, ".");
		}	
		
		public function getClassName():String
		{
			return qualifiedClassName.substr(qualifiedClassName.lastIndexOf(".") + 1);
		}	
	}
}