package com.zufangbao.turntable 
{
	import flash.display.Bitmap;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author zufangbao
	 */
	public class LoadedImageEvent extends Event 
	{
		public static const LOADED_IMAGE:String = "loadedImage";
		public var image:Bitmap;
		public function LoadedImageEvent(type:String, image:Bitmap) 
		{
			super(type, false, false);
			this.image = image;
		}
	}

}