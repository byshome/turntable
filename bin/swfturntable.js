/**
 * 抽奖大转盘
 * byshome@gmail.com
 * http://www.zufangbao.com
 * 2013-05-10
 */
var Turntable;
if (Turntable == undefined) {
	Turntable = function (settings) {
		this.initTurntable(settings);
	};
}
Turntable.prototype.initTurntable = function (settings) {
	try {
		this.settings = settings;
		this.movieName = "Turntable_" + Turntable.movieCount++;
		this.movieElement = null;
		// Setup global control tracking
		Turntable.instances[this.movieName] = this;
		// Load the settings.  Load the Flash movie.
		this.initSettings();
		this.loadFlash();
	} catch (ex) {
		delete Turntable.instances[this.movieName];
		throw ex;
	}
};
/* *************** */
/* Static Members  */
/* *************** */
Turntable.instances = {};
Turntable.movieCount = 0;
Turntable.version = "1.0.0";
/* ******************** */
/* Instance Members  */
/* ******************** */
// Private: initSettings ensures that all the
// settings are set, getting a default value if one was not assigned.
Turntable.prototype.initSettings = function () {
	this.ensureDefault = function (settingName, defaultValue) {
		this.settings[settingName] = (this.settings[settingName] == undefined) ? defaultValue : this.settings[settingName];
	};
	this.ensureDefault("width", 480);
	this.ensureDefault("height", 480);
	// image settings
	this.ensureDefault("imgBasePath", "");//图片的基准路径 当有提供时，后面的图片如果没有带协议路径，则会自动添加
	this.ensureDefault("imgTurntable", "");
	this.ensureDefault("imgPointer", "");
	this.ensureDefault("imgDisableBtn", "");
	this.ensureDefault("imgEnableBtn", "");
	this.ensureDefault("imgRunningBtn", "");
	this.ensureDefault("imgLotteryBtn", "");
	this.ensureDefault("imgSorryBtn", "");
	this.ensureDefault("awardCount", 8);//转盘上的奖品格数
	// button enabled?
	this.ensureDefault("btnEnabled", false);
	// Upload backend settings
	this.ensureDefault("requestUrl", "");
	this.ensureDefault("requestData", "");
	// Flash Settings
	this.ensureDefault("flash_url", "turntable.swf");
	this.ensureDefault("prevent_swf_caching", true);
	// Event Handlers
	this.ensureDefault("initCompleted_handler", null);
	this.ensureDefault("resetted_handler", null);
	this.ensureDefault("begin_handler", null);
	this.ensureDefault("urlRequestFailed_handler", null);
	this.ensureDefault("lotteryNotice_handler", null);
	
	// Update the flash url if needed
	if (!!this.settings.prevent_swf_caching) {
		this.settings.flash_url = this.settings.flash_url + (this.settings.flash_url.indexOf("?") < 0 ? "?" : "&") + "preventswfcaching=" + new Date().getTime();
	}
	delete this.ensureDefault;
};

// Private: loadFlash replaces the button_placeholder element with the flash movie.
Turntable.prototype.loadFlash = function () {
	var targetElement, tempParent;
	// Make sure an element with the ID we are going to use doesn't already exist
	if (document.getElementById(this.movieName) !== null) {
		throw "ID " + this.movieName + " is already in use. The Flash Object could not be added";
	}

	// Get the element where we will be placing the flash movie
	targetElement = document.getElementById(this.settings.placeholder_id) || this.settings.placeholder;
	if (targetElement == undefined) {
		throw "Could not find the placeholder element: " + this.settings.placeholder_id;
	}
	// Append the container and load the flash
	tempParent = document.createElement("div");
	tempParent.innerHTML = this.getFlashHTML();	// Using innerHTML is non-standard but the only sensible way to dynamically add Flash in IE (and maybe other browsers)
	targetElement.parentNode.replaceChild(tempParent.firstChild, targetElement);

	// Fix IE Flash/Form bug
	if (window[this.movieName] == undefined) {
		window[this.movieName] = this.getMovieElement();
	}
};

// Private: getFlashHTML generates the object tag needed to embed the flash in to the document
Turntable.prototype.getFlashHTML = function () {
	// Flash Satay object syntax: http://www.alistapart.com/articles/flashsatay
	return ['<object id="', this.movieName, '" type="application/x-shockwave-flash" data="', this.settings.flash_url, '" width="', this.settings.width, '" height="', this.settings.height, '" class="Turntable">',
				'<param name="wmode" value="window" />',
				'<param name="movie" value="', this.settings.flash_url, '" />',
				'<param name="quality" value="high" />',
				'<param name="menu" value="false" />',
				'<param name="allowScriptAccess" value="always" />',
				'<param name="flashvars" value="' + this.getFlashVars() + '" />',
				'</object>'].join("");
};

// Private: getFlashVars builds the parameter string that will be passed
// to flash in the flashvars param.
Turntable.prototype.getFlashVars = function () {
	// Build the parameter string
	return ["movieName=", encodeURIComponent(this.movieName),
	        "&amp;imgBasePath=", encodeURIComponent(this.settings.imgBasePath),
			"&amp;btnEnabled=", encodeURIComponent(this.settings.btnEnabled),
			"&amp;awardCount=", encodeURIComponent(this.settings.awardCount),
			"&amp;requestUrl=", encodeURIComponent(this.settings.requestUrl),
			"&amp;requestData=", encodeURIComponent(this.settings.requestData),
			"&amp;imgTurntable=", encodeURIComponent(this.settings.imgTurntable),
			"&amp;imgPointer=", encodeURIComponent(this.settings.imgPointer),
			"&amp;imgDisableBtn=", encodeURIComponent(this.settings.imgDisableBtn),
			"&amp;imgEnableBtn=", encodeURIComponent(this.settings.imgEnableBtn),
			"&amp;imgRunningBtn=", encodeURIComponent(this.settings.imgRunningBtn),
			"&amp;imgLotteryBtn=", encodeURIComponent(this.settings.imgLotteryBtn),
			"&amp;imgSorryBtn=", encodeURIComponent(this.settings.imgSorryBtn)
		].join("");
};

// Public: getMovieElement retrieves the DOM reference to the Flash element added by Turntable
// The element is cached after the first lookup
Turntable.prototype.getMovieElement = function () {
	if (this.movieElement == undefined) {
		this.movieElement = document.getElementById(this.movieName);
	}

	if (this.movieElement === null) {
		throw "Could not find Flash element";
	}
	
	return this.movieElement;
};
/* Note: addSetting and getSetting are no longer used by Turntable but are included
	the maintain v2 API compatibility
*/
// Public: (Deprecated) addSetting adds a setting value. If the value given is undefined or null then the default_value is used.
Turntable.prototype.addSetting = function (name, value, default_value) {
    if (value == undefined) {
        return (this.settings[name] = default_value);
    } else {
        return (this.settings[name] = value);
	}
};

// Public: (Deprecated) getSetting gets a setting. Returns an empty string if the setting was not found.
Turntable.prototype.getSetting = function (name) {
    if (this.settings[name] != undefined) {
        return this.settings[name];
	}
    return "";
};

// Private: callFlash handles function calls made to the Flash element.
// Calls are made with a setTimeout for some functions to work around
// bugs in the ExternalInterface library.
Turntable.prototype.callFlash = function (functionName, argumentArray) {
	argumentArray = argumentArray || [];
	
	var movieElement = this.getMovieElement();
	var returnValue, returnString;

	// Flash's method if calling ExternalInterface methods (code adapted from MooTools).
	try {
		returnString = movieElement.CallFunction('<invoke name="' + functionName + '" returntype="javascript">' + __flash__argumentsToXML(argumentArray, 0) + '</invoke>');
		returnValue = eval(returnString);
	} catch (ex) {
		throw "Call to " + functionName + " failed";
	}
	
	// Unescape file post param values
	if (returnValue != undefined && typeof returnValue.post === "object") {
		returnValue = this.unescapeFilePostParams(returnValue);
	}

	return returnValue;
};

/* *****************************
	-- Flash control methods --
	Your UI should use these
	to operate Turntable
   ***************************** */
/**
 * 重置
 */
Turntable.prototype.doReset = function () {
	this.callFlash("doReset");
};
// Private: This event is called by Flash when it has finished loading. Don't modify this.
// Use the Turntable_loaded_handler event setting to execute custom code when Turntable has loaded.
Turntable.prototype.flashReady = function () {
	// Check that the movie element is loaded correctly with its ExternalInterface methods defined
	var movieElement = this.getMovieElement();

	if (!movieElement) {
		this.debug("Flash called back ready but the flash movie can't be found.");
		return;
	}

	this.cleanUp(movieElement);
};

// Private: removes Flash added fuctions to the DOM node to prevent memory leaks in IE.
// This function is called by Flash each time the ExternalInterface functions are created.
Turntable.prototype.cleanUp = function (movieElement) {
	// Pro-actively unhook all the Flash functions
	try {
		if (this.movieElement && typeof(movieElement.CallFunction) === "unknown") { // We only want to do this in IE
			this.debug("Removing Flash functions hooks (this should only run in IE and should prevent memory leaks)");
			for (var key in movieElement) {
				try {
					if (typeof(movieElement[key]) === "function") {
						movieElement[key] = null;
					}
				} catch (ex) {
				}
			}
		}
	} catch (ex1) {
	
	}

	// Fix Flashes own cleanup code so if the SWFMovie was removed from the page
	// it doesn't display errors.
	window["__flash__removeCallback"] = function (instance, name) {
		try {
			if (instance) {
				instance[name] = null;
			}
		} catch (flashEx) {
		
		}
	};

};
/**初始化完成通知*/
Turntable.prototype.initCompleted = function (success) {
	if (typeof this.settings.initCompleted_handler === "function") {
		this.settings.initCompleted_handler(success);
	}
};
/**重置成功*/
Turntable.prototype.resetted = function () {
	if (typeof this.settings.resetted_handler === "function") {
		this.settings.resetted_handler();
	}
};
/**开始抽奖*/
Turntable.prototype.begin = function () {
	if (typeof this.settings.begin_handler === "function") {
		this.settings.begin_handler();
	}
};
/**URL请求出错*/
Turntable.prototype.urlRequestFailed = function (code, msg) {
	if (typeof this.settings.urlRequestFailed_handler === "function") {
		this.settings.urlRequestFailed_handler(code, msg);
	}
};
/**抽奖结果通知*/
Turntable.prototype.lotteryNotice = function (awardLevel, awardMsg) {
	if (typeof this.settings.lotteryNotice_handler === "function") {
		this.settings.lotteryNotice_handler(awardLevel, awardMsg);
	}
};