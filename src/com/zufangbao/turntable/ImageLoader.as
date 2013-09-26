package com.zufangbao.turntable 
{
	import org.flashdevelop.utils.FlashConnect;
	import flash.display.Loader;
	import org.bytearray.gif.player.GIFPlayer;
	import com.adobe.utils.StringUtil;
	import flash.net.URLRequest;
	import flash.display.Bitmap;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 * ...
	 * @author zufangbao
	 */
	public class ImageLoader extends EventDispatcher
	{
		private var url:String;
		public function ImageLoader() 
		{
		}
		/**
		 * 加载图片
		 * @param	baseUrl 基准的图片URL 如果没有，则不附加
		 * @param	url 图片的URL，如果带有协议符:，则不附加baseUrl 否则需要附加baseUrl
		 * @return
		 */
		public function load(baseUrl:String, url:String):Boolean {
			this.url = url;
			if (url == null || url.length == 0 || url == "undefined") {
				return false;
			}
			if (url.indexOf(":") == -1 && baseUrl != null && baseUrl.length > 0) {
				if (!StringUtil.endsWith(baseUrl, "/") && !StringUtil.endsWith(baseUrl, "\\") && !StringUtil.beginsWith(url, "/") && !StringUtil.beginsWith(url, "\\")) {
					url = baseUrl + "/" + url;
				}else {
					url = baseUrl + url;
				}
			}
			if (StringUtil.endsWith(url.toLocaleLowerCase(), ".gif")) {
				var gifImage:GIFPlayer = new GIFPlayer();
				gifImage.load(new URLRequest(url));
				gifImage.addEventListener(IOErrorEvent.IO_ERROR, loadImageFailed);
				gifImage.addEventListener(IOErrorEvent.NETWORK_ERROR, loadImageFailed);
				dispatchEvent(new LoadedImageEvent(LoadedImageEvent.LOADED_IMAGE, gifImage));
			}else {
				var imgLoader:Loader = new Loader();
				imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void {
					var image:Bitmap = Bitmap(imgLoader.content);
					dispatchEvent(new LoadedImageEvent(LoadedImageEvent.LOADED_IMAGE, image));
				});
				imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadImageFailed);
				imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, loadImageFailed);
				imgLoader.load(new URLRequest(url));
			}
			return true;
		}
		/**
		 * 加载图片出错
		 * @param	event
		 */
		private function loadImageFailed(event:IOErrorEvent):void {
			dispatchEvent(new LoadFailedEvent(LoadFailedEvent.LOAD_FAILED, Number(event.errorID), event.text, this.url));
		}
	}

}