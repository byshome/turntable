package com.zufangbao.turntable
{
	import com.adobe.serialization.json.JSON;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;
	import flash.system.Security;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	import org.flashdevelop.utils.FlashConnect;
	import flash.display.Loader;
	import org.bytearray.gif.player.GIFPlayer;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import com.adobe.utils.StringUtil;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	
	
	/**
	 * @date 2013-09-22
	 * @author byshome@gmail.com
	 */
	public class Main extends Sprite 
	{
		private var movieName:String;
		//主要回调
		private var initCompleted_Callback:String;
		private var resetted_Callback:String;
		private var begin_Callback:String;
		private var urlRequestFailed_Callback:String;
		private var lotteryNotice_Callback:String;
		/**
		 * 是否初始化完成
		 */
		private var inited:Boolean = false;
		/**
		 * 是否通知过URL请求失败过
		 */
		private var urlRequestFailedNoticed:Boolean = false;
		private var awardCount:int = 0;//总共奖品格子数
		private var imgTurntable:Bitmap = null;
		private var imgPointer:Bitmap = null;
		private var imgDisableBtn:Bitmap = null;
		private var imgEnableBtn:Bitmap = null;
		private var spriteEnableBtn:Sprite = null;//图片是不可以直接点击的，所以需要把图片加到Sprite中
		private var imgRunningBtn:Bitmap = null;
		private var imgLotteryBtn:Bitmap = null;
		private var imgSorryBtn:Bitmap = null;
		private var btnEnabled:Boolean = false;//按钮是否可用
		private var requestUrl:String = null;//服务器请求的URL
		private var requestData:String = "";//附加请求的数据
		private var awardIndex:int;//获奖的索引号
		private var awardLevel:Number;//获奖的奖品等级
		private var awardMsg:String;//获奖的提示消息
		private var maxSpeed:Number = 0;//转盘初速度,亦即最大速度,之后开始做匀减速运动
		private var acceleratedSpeed:Number = 0;//加速度
		private var runningTime:Number = 0;//已经转动的时间计数器
		private var nowRotation:Number = 0;//当前的角度
		private var totalRotation:Number = 0;//总的转动角度
		private var originalMatrix:Matrix;//原始的指针的Matrix
		
		public function Main():void {
			FlashConnect.trace("Turntable init...");
			Security.allowDomain("*");//允许上传到任何的域名下
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			//绑定交互事件
			this.movieName = root.loaderInfo.parameters.movieName;
			this.initCompleted_Callback = "Turntable.instances[\"" + this.movieName + "\"].initCompleted";
			this.resetted_Callback = "Turntable.instances[\"" + this.movieName + "\"].resetted";
			this.begin_Callback = "Turntable.instances[\"" + this.movieName + "\"].begin";
			this.urlRequestFailed_Callback = "Turntable.instances[\"" + this.movieName + "\"].urlRequestFailed";
			this.lotteryNotice_Callback = "Turntable.instances[\"" + this.movieName + "\"].lotteryNotice";
			if (!this.parseParams()) {//绑定参数
				FlashConnect.trace("parseParams failed.");
				ExternalCall.initCompleted(this.initCompleted_Callback, false);//不成功
			}
			//绑定js方法
			ExternalInterface.addCallback("doReset", this.doReset);
		}
		/**
		 * 接受传入的参数
		 */
		private function parseParams():Boolean
		{
			try {
				//是否可用
				this.btnEnabled = Boolean(root.loaderInfo.parameters.btnEnabled);
				this.requestUrl = String(root.loaderInfo.parameters.requestUrl);//请求的URL
				if (this.requestUrl == null || requestUrl.length == 0 || requestUrl == "undefined") {
					FlashConnect.trace("未指定抽奖服务");
					return false;
				}
				this.requestData = String(root.loaderInfo.parameters.requestData);//接收请求的数据
				if (this.requestData == null) {
					this.requestData = "";
				}
				var strAwardCount:String = String(root.loaderInfo.parameters.awardCount);
				if (strAwardCount == null || strAwardCount.length == 0 || strAwardCount == "undefined") {
					FlashConnect.trace("未设置转盘奖品数");
					return false;
				}
				this.awardCount = Number(strAwardCount);
				if (this.awardCount < 4) {
					FlashConnect.trace("未设置转盘数不能小于4");
					return false;
				}
				//图片的基准路径
				var imgBasePath:String = String(root.loaderInfo.parameters.imgBasePath);
				//背景图
				var imgTurntableUrl:String = String(root.loaderInfo.parameters.imgTurntable);
				var imgTurntableLoader:ImageLoader = new ImageLoader();
				imgTurntableLoader.addEventListener(LoadedImageEvent.LOADED_IMAGE, function(event:LoadedImageEvent):void {
						imgTurntable = event.image;
						initUI();//完成布局
					});
				imgTurntableLoader.addEventListener(LoadFailedEvent.LOAD_FAILED, function(event:LoadFailedEvent):void {
						loadImageFailed(event.code, event.msg, event.url);
					});
				if (!imgTurntableLoader.load(imgBasePath, imgTurntableUrl)) {
					return false;
				}
				//指针图
				var imgPointerUrl:String = String(root.loaderInfo.parameters.imgPointer);
				var imgPointerLoader:ImageLoader = new ImageLoader();
				imgPointerLoader.addEventListener(LoadedImageEvent.LOADED_IMAGE, function(event:LoadedImageEvent):void {
						imgPointer = event.image;
						initUI();//完成布局
					});
				imgPointerLoader.addEventListener(LoadFailedEvent.LOAD_FAILED, function(event:LoadFailedEvent):void {
						loadImageFailed(event.code, event.msg, event.url);
					});
				if (!imgPointerLoader.load(imgBasePath, imgPointerUrl)) {
					return false;
				}
				//按钮图--不可用状态
				var imgDisableBtnUrl:String = String(root.loaderInfo.parameters.imgDisableBtn);
				var imgDisableBtnLoader:ImageLoader = new ImageLoader();
				imgDisableBtnLoader.addEventListener(LoadedImageEvent.LOADED_IMAGE, function(event:LoadedImageEvent):void {
						imgDisableBtn = event.image;
						initUI();//完成布局
					});
				imgDisableBtnLoader.addEventListener(LoadFailedEvent.LOAD_FAILED, function(event:LoadFailedEvent):void {
						loadImageFailed(event.code, event.msg, event.url);
					});
				if (!imgDisableBtnLoader.load(imgBasePath, imgDisableBtnUrl)) {
					return false;
				}
				//按钮图--可用状态
				var imgEnableBtnUrl:String = String(root.loaderInfo.parameters.imgEnableBtn);
				var imgEnableBtnLoader:ImageLoader = new ImageLoader();
				imgEnableBtnLoader.addEventListener(LoadedImageEvent.LOADED_IMAGE, function(event:LoadedImageEvent):void {
						imgEnableBtn = event.image;
						initUI();//完成布局
					});
				imgEnableBtnLoader.addEventListener(LoadFailedEvent.LOAD_FAILED, function(event:LoadFailedEvent):void {
						loadImageFailed(event.code, event.msg, event.url);
					});
				if (!imgEnableBtnLoader.load(imgBasePath, imgEnableBtnUrl)) {
					return false;
				}
				var imgRunningBtnUrl:String = String(root.loaderInfo.parameters.imgRunningBtn);
				var imgRunningBtnLoader:ImageLoader = new ImageLoader();
				imgRunningBtnLoader.addEventListener(LoadedImageEvent.LOADED_IMAGE, function(event:LoadedImageEvent):void {
						imgRunningBtn = event.image;
						initUI();//完成布局
					});
				imgRunningBtnLoader.addEventListener(LoadFailedEvent.LOAD_FAILED, function(event:LoadFailedEvent):void {
						loadImageFailed(event.code, event.msg, event.url);
					});
				if (!imgRunningBtnLoader.load(imgBasePath, imgRunningBtnUrl)) {
					return false;
				}
				//按钮图--中奖效果
				var imgLotteryBtnUrl:String = String(root.loaderInfo.parameters.imgLotteryBtn);
				var imgLotteryBtnLoader:ImageLoader = new ImageLoader();
				imgLotteryBtnLoader.addEventListener(LoadedImageEvent.LOADED_IMAGE, function(event:LoadedImageEvent):void {
						imgLotteryBtn = event.image;
						initUI();//完成布局
					});
				imgLotteryBtnLoader.addEventListener(LoadFailedEvent.LOAD_FAILED, function(event:LoadFailedEvent):void {
						loadImageFailed(event.code, event.msg, event.url);
					});
				if (!imgLotteryBtnLoader.load(imgBasePath, imgLotteryBtnUrl)) {
					return false;
				}
				//按钮图--未中奖效果
				var imgSorryBtnUrl:String = String(root.loaderInfo.parameters.imgSorryBtn);
				var imgSorryBtnLoader:ImageLoader = new ImageLoader();
				imgSorryBtnLoader.addEventListener(LoadedImageEvent.LOADED_IMAGE, function(event:LoadedImageEvent):void {
						imgSorryBtn = event.image;
						initUI();//完成布局
					});
				imgSorryBtnLoader.addEventListener(LoadFailedEvent.LOAD_FAILED, function(event:LoadFailedEvent):void {
						loadImageFailed(event.code, event.msg, event.url);
					});
				if (!imgSorryBtnLoader.load(imgBasePath, imgSorryBtnUrl)) {
					return false;
				}
			} catch (ex:Object) {
				FlashConnect.trace(ex);
				return false;
			}
			return true;
		}
		/**
		 * 加载图片出错
		 */
		private function loadImageFailed(code:Number, msg:String, url:String):void {
			FlashConnect.trace("加载图片" + url + "出错，" + String(code) + ":" + msg);
			this.doUrlRequestFailed(code, "加载资源图片出错");
		}
		/**
		 * 初始化UI
		 */
		private function initUI():void {
			if (this.imgTurntable == null || this.imgPointer == null || this.imgDisableBtn == null
				|| this.imgRunningBtn == null || this.imgEnableBtn == null || this.imgLotteryBtn == null || this.imgSorryBtn == null){
				return;
			}
			//布局
			this.imgTurntable.width = this.stage.stageWidth;
			this.imgTurntable.height = this.stage.stageHeight;
			this.imgTurntable.smoothing = true;
			this.stage.addChild(this.imgTurntable);
			this.imgPointer.x = (this.stage.stageWidth - this.imgPointer.width) / 2;
			this.imgPointer.y = (this.stage.stageHeight - this.imgPointer.height) / 2;
			this.imgPointer.smoothing = true;
			this.stage.addChild(this.imgPointer);
			this.originalMatrix = this.imgPointer.transform.matrix;//原始的角度
			
			this.imgDisableBtn.x = (this.stage.stageWidth - this.imgDisableBtn.width) / 2;
			this.imgDisableBtn.y = (this.stage.stageHeight - this.imgDisableBtn.height) / 2;
			this.imgDisableBtn.visible = !this.btnEnabled;
			this.stage.addChild(this.imgDisableBtn);
			//Bitmap无法直接用Click所以使用Sprite
			this.spriteEnableBtn = new Sprite();
			this.spriteEnableBtn.graphics.beginBitmapFill(this.imgEnableBtn.bitmapData);
			this.spriteEnableBtn.graphics.drawRect(0, 0, this.imgEnableBtn.width, this.imgEnableBtn.height);
			this.spriteEnableBtn.x = (this.stage.stageWidth - this.imgEnableBtn.width) / 2;
			this.spriteEnableBtn.y = (this.stage.stageHeight - this.imgEnableBtn.height) / 2;
			this.spriteEnableBtn.width = this.imgEnableBtn.width;
			this.spriteEnableBtn.height = this.imgEnableBtn.height;
			this.spriteEnableBtn.visible = this.btnEnabled;
			this.spriteEnableBtn.buttonMode = true;
			this.stage.addChild(this.spriteEnableBtn);
			this.spriteEnableBtn.addEventListener(MouseEvent.CLICK, doBegin);//开始抽奖
			
			this.imgRunningBtn.x = (this.stage.stageWidth - this.imgRunningBtn.width) / 2;
			this.imgRunningBtn.y = (this.stage.stageHeight - this.imgRunningBtn.height) / 2;
			this.imgRunningBtn.visible = false;
			this.imgRunningBtn.smoothing = true;
			this.stage.addChild(this.imgRunningBtn);
			
			this.imgLotteryBtn.x = (this.stage.stageWidth - this.imgLotteryBtn.width) / 2;
			this.imgLotteryBtn.y = (this.stage.stageHeight - this.imgLotteryBtn.height) / 2;
			this.imgLotteryBtn.visible = false;
			this.imgLotteryBtn.smoothing = true;
			this.stage.addChild(this.imgLotteryBtn);
			
			this.imgSorryBtn.x = (this.stage.stageWidth - this.imgSorryBtn.width) / 2;
			this.imgSorryBtn.y = (this.stage.stageHeight - this.imgSorryBtn.height) / 2;
			this.imgSorryBtn.visible = false;
			this.imgSorryBtn.smoothing = true;
			this.stage.addChild(this.imgSorryBtn);
			this.inited = true;//初始化完成标志
			ExternalCall.initCompleted(this.initCompleted_Callback, true);
		}
		/**
		 * 执行通知URL请求失败
		 * @param	code
		 * @param	msg
		 */
		private function doUrlRequestFailed(code:Number, msg:String):void {
			if (this.urlRequestFailedNoticed) return;
			this.urlRequestFailedNoticed = true;//不重复通知加载出错
			ExternalCall.urlRequestFailed(this.urlRequestFailed_Callback, code, msg);
		}
		/**
		 * 重置
		 */
		private function doReset():void {
			//没有通过初始化不允许重置
			if (!this.inited) {
				return;
			}
			//重置
			this.urlRequestFailedNoticed = false;
			this.rotateAroundCenter(this.imgPointer, 0, this.originalMatrix);//转加0度角
			this.imgRunningBtn.visible = false;
			this.spriteEnableBtn.visible = true;
			//发送通知
			ExternalCall.resetted(this.resetted_Callback);
		}
		/**
		 * 开始抽奖
		 */
		public function doBegin(event:MouseEvent):void {
			this.spriteEnableBtn.visible = false;
			this.imgRunningBtn.visible = true;
			//this.doBeginTurntable(2, 1, "恭喜您，中了一等奖");
			//请求URL
			var urlLoader:URLLoader = new URLLoader();
			var urlRequest:URLRequest = new URLRequest(this.requestUrl);
			urlRequest.method = URLRequestMethod.POST;
			urlRequest.data = "t=" + String(new Date().getTime());
			if (this.requestData.length > 0) {
				urlRequest.data += "&" + this.requestData;
			}
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.COMPLETE, function(event:Event):void {
					var responeText:String = String((event.currentTarget as URLLoader).data);
					parseServiceResponse(responeText);//
				});
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void {
					FlashConnect.trace("请求服务器出错" + String(event.errorID) + ":" + event.text);
					doUrlRequestFailed(999, "请求服务器出错");
				});
			urlLoader.load(urlRequest);
		}
		/**
		 * 解析服务器应答{"resultCode":1,"resultMsg":"","data":{"awardLevel":1,"awardMsg":"恭喜您，中了一等奖","awardIndex":2}}
		 * resultCode为1的，说明获取成功，否则是错误代码，resultMsg为错误消息
		 * awardLevel:奖品等级 0未中奖，1是1等奖...
		 * awardIndex:2是中奖对应转盘上的索引号，从0开始
		 * awardMsg:返回到客户端的提示信息
		 * @param	response
		 */
		private function parseServiceResponse(response:String):void {
			FlashConnect.trace(response);
			try {
				var dict:Object = JSON.decode(response);
				var resultCode:Number = Number(dict["resultCode"]);
				var resultMsg:String = String(dict["resultMsg"]);
				if (resultCode != 1) {
					doUrlRequestFailed(1000 + resultCode, resultMsg);
					FlashConnect.trace("请求服务器返回" + String(resultCode) + ":" + resultMsg);
					return;
				}
				var data:Object = Object(dict["data"]);
				var awardIndex:int = int(data["awardIndex"]);
				var awardLevel:Number = Number(data["awardLevel"]);
				var awardMsg:String = String(data["awardMsg"]);
				this.doBeginTurntable(awardIndex, awardLevel, awardMsg);
			}catch (ex:Object) {
				FlashConnect.trace(ex);
				doUrlRequestFailed(9999, "获取服务器应答出错");
			}
		}
		/**
		 * 开始转盘
		 * @param	awardIndex
		 * @param	awardLevel
		 * @param	msg
		 */
		private function doBeginTurntable(awardIndex:int, awardLevel:Number, awardMsg:String):void {
			FlashConnect.trace("doBeginTurntable...");
			awardIndex = awardIndex % this.awardCount;//取模
			this.awardIndex = awardIndex;
			this.awardLevel = awardLevel;
			this.awardMsg = awardMsg;
			this.nowRotation = 0;//当前角度为0
			var angle:Number = 360 / this.awardCount;//单个奖品的角度
			//计算本次的总角度 转5圈
			this.totalRotation = 5 * 360 + (angle * awardIndex) % 360;
			//随机额外多移动一点,但不超过既定奖项的区域
			var randomOffset:Number = Math.random() * angle / 2  + angle / 4;
			this.totalRotation += randomOffset;//总角度
			FlashConnect.trace("总转动角度" + String(this.totalRotation));
			//花费5秒,单位时间取决于Timer的执行频率 50ms的timer
			var needTime:int = 5 * 20;
			//计算初速度
			this.maxSpeed =  2 * totalRotation / needTime;
			//计算加速度
			this.acceleratedSpeed = this.maxSpeed / needTime;
			//将运动时间置为0
			this.runningTime = 0;
			var timer:Timer = new Timer(50, needTime);
			timer.addEventListener(TimerEvent.TIMER, runTurntable);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, turntableCompleted);
			timer.start();
		}
		/**
		 * 转盘转动
		 * @param	event
		 */
		private function runTurntable(event:TimerEvent):void {
			//刷新目前转盘的角度
			var addAngle:Number = this.maxSpeed * this.runningTime -  this.acceleratedSpeed * this.runningTime * this.runningTime / 2;
			this.nowRotation = addAngle;
			this.runningTime++;
			this.rotateAroundCenter(this.imgPointer, this.nowRotation, this.originalMatrix);
		}
		/**
		 * 旋转 中心点
		 * @param	dis
		 * @param	rotation
		 */
		public function rotateAroundCenter (ob:DisplayObject, rotation:Number, srcMatrix:Matrix):void
		{
			var matrix:Matrix = srcMatrix.clone();
			//var left:Number = (this.stage.stageWidth - ob.width) / 2;//由于需要再次计算left, 用于计算中间点
			//var top:Number = (this.stage.stageHeight- ob.height) / 2;//由于需要再次计算top, 用于计算中间点
			//var dx:Number = (left + (ob.width / 2));
			//var dy:Number = (top + (ob.height / 2));
			var dx:Number = this.stage.stageWidth / 2;//直接居中
			var dy:Number = this.stage.stageHeight / 2;//直接居中
			matrix.translate(-dx, -dy); 
			var rotate:Number = (rotation % 360) / 180 * Math.PI;
			matrix.rotate(rotate); 
			matrix.translate(dx, dy);
			ob.transform.matrix = matrix;
		}
		/**
		 * 运行完成
		 * @param	event
		 */
		private function turntableCompleted(event:TimerEvent):void {
			this.rotateAroundCenter(this.imgPointer, this.totalRotation, this.originalMatrix);//转到指定位置
			this.imgRunningBtn.visible = false;
			this.imgLotteryBtn.visible = this.awardLevel > 0;
			this.imgSorryBtn.visible = this.awardLevel == 0;
			ExternalCall.lotteryNotice(this.lotteryNotice_Callback, this.awardLevel, this.awardMsg);
		}
	}
	
}