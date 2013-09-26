package com.zufangbao.turntable 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author zufangbao
	 */
	public class LoadFailedEvent extends Event 
	{
		public static const LOAD_FAILED:String = "loadFailed";
		public var code:Number;
		public var msg:String;
		public var url:String;
		public function LoadFailedEvent(type:String, code:Number, msg:String, url:String) 
		{
			super(type, false, false);
			this.code = code;
			this.msg = msg;
			this.url = url;
		}
		
	}

}