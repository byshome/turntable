package com.zufangbao.turntable 
{
	import flash.external.ExternalInterface;
	/**
	 * js交互
	 * byshome@gmail.com
	 * http://www.zufangbao.com
	 * 2013-05-10
	 */
	internal class ExternalCall 
	{
		
		public function ExternalCall() 
		{
		}
		/**
		 * 初始化完成通知
		 * @param	callback
		 */
		public static function initCompleted(callback:String, success:Boolean):void {
			ExternalInterface.call(callback, escapeMessage(success));
		}
		/**
		 * 重置完成状态通知
		 * @param	callback
		 */
		public static function resetted(callback:String):void {
			ExternalInterface.call(callback);
		}
		/**
		 * 开始抽奖通知
		 * @param	callback
		 */
		public static function begin(callback:String):void {
			ExternalInterface.call(callback);
		}
		/**
		 * 请求URL失败的通知
		 * @param	callback
		 * @param	code 请求失败的代码
		 * @param	msg 请求失败的消息
		 */
		public static function urlRequestFailed(callback:String, code:Number, msg:String):void {
			ExternalInterface.call(callback, escapeMessage(code), escapeMessage(msg));
		}
		/**
		 * 中奖通知
		 * @param	callback
		 * @param	awardLevel 奖品等级 0为未中奖
		 * @param	msg 中奖显示的通知消息
		 */
		public static function lotteryNotice(callback:String, awardLevel:Number, awardMsg:String):void {
			ExternalInterface.call(callback, escapeMessage(awardLevel), escapeMessage(awardMsg));
		}
		/* Escapes all the backslashes which are not translated correctly in the Flash -> JavaScript Interface
		 * 
		 * These functions had to be developed because the ExternalInterface has a bug that simply places the
		 * value a string in quotes (except for a " which is escaped) in a JavaScript string literal which
		 * is executed by the browser.  These often results in improperly escaped string literals if your
		 * input string has any backslash characters. For example the string:
		 * 		"c:\Program Files\uploadtools\"
		 * is placed in a string literal (with quotes escaped) and becomes:
		 * 		var __flash__temp = "\"c:\Program Files\uploadtools\\"";
		 * This statement will cause errors when executed by the JavaScript interpreter:
		 * 	1) The first \" is succesfully transformed to a "
		 *  2) \P is translated to P and the \ is lost
		 *  3) \u is interpreted as a unicode character and causes an error in IE
		 *  4) \\ is translated to \
		 *  5) leaving an unescaped " which causes an error
		 * 
		 * I fixed this by escaping \ characters in all outgoing strings.  The above escaped string becomes:
		 * 		var __flash__temp = "\"c:\\Program Files\\uploadtools\\\"";
		 * which contains the correct string literal.
		 * 
		 * Note: The "var __flash__temp = " portion of the example is part of the ExternalInterface not part of
		 * my escaping routine.
		 */
		private static function escapeMessage(message:*):* {
			if (message is String) {
				message = escapeString(message);
			}
			else if (message is Array) {
				message = escapeArray(message);
			}
			else if (message is Object) {
				message = escapeObject(message);
			}
			
			return message;
		}
		
		private static function escapeString(message:String):String {
			var replacePattern:RegExp = /\\/g; //new RegExp("/\\/", "g");
			return message.replace(replacePattern, "\\\\");
		}
		private static function escapeArray(message_array:Array):Array {
			var length:uint = message_array.length;
			var i:uint = 0;
			for (i; i < length; i++) {
				message_array[i] = escapeMessage(message_array[i]);
			}
			return message_array;
		}
		private static function escapeObject(message_obj:Object):Object {
			for (var name:String in message_obj) {
				message_obj[name] = escapeMessage(message_obj[name]);
			}
			return message_obj;
		}
	}
}