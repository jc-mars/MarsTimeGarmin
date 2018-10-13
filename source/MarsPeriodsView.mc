using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

class MarsPeriodsView extends WatchUi.View {

    var font = Graphics.FONT_LARGE;
    var longishFont = WatchUi.loadResource(Rez.Fonts.longishFont);
    var lineSpacing = Graphics.getFontHeight(longishFont);
    var centerY = 0;
    var centerX = 0;
    var top = 0;
    var bottom = 0;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MarsWidget(dc));
		/*      
        dc.setColor( Graphics.COLOR_BLACK, Graphics.COLOR_BLACK );
        dc.clear();
        dc.setColor( Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT );
        */
        centerY = (dc.getHeight() / 2) - (lineSpacing / 2);
        centerX = (dc.getWidth()/2);
        top = 0;
        bottom = dc.getHeight() - Graphics.getFontHeight(font);
        /*
        
        //period
        var now = new Time.Moment(Time.now().value());
        dc.drawText( centerX, 0, font, calendarMarsDate(now), Graphics.TEXT_JUSTIFY_CENTER );

		// date and time
		var todayDateTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		
		//time
		var timeString = Lang.format("$1$:$2$",[todayDateTime.hour, todayDateTime.min.format("%02d")]);
        dc.drawText( centerX, centerY, longishFont, timeString, Graphics.TEXT_JUSTIFY_CENTER );
		
		//date
		var dateString = Lang.format("$1$ $2$ $3$",[todayDateTime.day,todayDateTime.month,todayDateTime.year]);
        dc.drawText( centerX, dc.getHeight() - Graphics.getFontHeight(font) , font, dateString , Graphics.TEXT_JUSTIFY_CENTER );
        */    
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    	
		// period
		var now = new Time.Moment(Time.now().value());
		var viewPeriod = View.findDrawableById("MarsPeriodLabel");
		//viewPeriod.setFont(font);
		viewPeriod.setLocation(centerX, top);
        viewPeriod.setText(calendarMarsDate(now));
        
        // time
        var todayDateTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var timeString = Lang.format("$1$:$2$",[todayDateTime.hour, todayDateTime.min.format("%02d")]);
        var viewTime = View.findDrawableById("TimeLabel");
        viewTime.setFont(longishFont);
        viewTime.setLocation(centerX, centerY);
        viewTime.setText(timeString);
        
        // date
		var dateString = Lang.format("$1$ $2$ $3$",[todayDateTime.day,todayDateTime.month,todayDateTime.year]);
    	var viewDate = View.findDrawableById("DateLabel");
        //viewDate.setFont(font);
        viewDate.setLocation(centerX, bottom);
        viewDate.setText(dateString);
    	
    }
    
    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
  
	// function nbWeeksInP13 returns number of weeks (integer) in P13
	// function takes a year (integer) as parameter
	// Beta from the MarsTime technical specs
	// refer to https://developer.garmin.com/connect-iq/api-docs/ regarding moment and duration in Garmin SDK
	function nbWeeksInP13(marsyear) {
		var yearCurrentMoment = startDateOfMarsYear(marsyear);  //get garmin moment for this year start date
		var yearNextMoment = startDateOfMarsYear(marsyear + 1); //get garmin moment for next year start date
		var days12x28 = new Time.Duration(29030400); // 12 periods of 28 days times number of second in one day
		var p12Current = yearCurrentMoment.add(days12x28); //moment in this year that correspond to end of P12
		var momentDiff = yearNextMoment.subtract(p12Current); //get duration between the 2 moments (start of next year P1 minus end of P12 current year)
		var nbDays = momentDiff.value()/86400; //86400 is number of seconds in one day.

		var nbWP13 = 1; //error code 1
		switch (nbDays.toNumber()) {
			case 28:
				nbWP13 = 4;
				break;
			case 35:
				nbWP13 = 5;
				break;
		}
		return nbWP13;
	}
	
	// function startDate returns the first day of the Mars year in a Garmin moment format
	// that contains the input year (integer) 
	function startDateOfMarsYear(marsyear) {
		var options = {
    		:year   => marsyear,
    		:month  => 1,
    		:day    => 1
		};
		var date = Gregorian.moment(options);
		var iDay = Gregorian.info(date, Time.FORMAT_SHORT).day_of_week;
		//System.println(iDay);
		switch (iDay) {
			case 1:
				options = {:year => marsyear, :month => 1, :day => 1};
				break;
			case 2:
				options = {:year => marsyear - 1, :month => 12, :day => 31};
				break;
			case 3:
				options = {:year => marsyear - 1, :month => 12, :day => 30};
				break;
			case 4:
				options = {:year => marsyear - 1, :month => 12, :day => 29};
				break;
			case 5:
				options = {:year => marsyear - 1, :month => 12, :day => 28};
				break;
			case 6:
				options = {:year => marsyear, :month => 12, :day => 3};
				break;
			case 7:
				options = {:year => marsyear, :month => 12, :day => 2};
				break;
		} 
		return Gregorian.moment(options);
	}
	
	// function calendarMarsDate convert a garmin moment into a Mars Calendar Periodic format: PxxWyyDz
	function calendarMarsDate(garminMomentNow) {
		var date = Gregorian.info(garminMomentNow, Time.FORMAT_SHORT);
		var marsYear = date.year;
		var yearStart = startDateOfMarsYear(marsYear);
		
		// if now is earlier than start of the Mars year, we are in previous Mars year...
		if ( garminMomentNow.lessThan(yearStart) ) {
			marsYear = marsYear.toNumber() - 1;
			yearStart = startDateOfMarsYear(marsYear);
		}
		
		var nbDays = garminMomentNow.subtract(yearStart).value()/86400; // 86400 is the number of seconds in one day
		var nbWeeks = nbDays.toNumber()/7;
		var mPeriod = (nbWeeks / 4) + 1;
		var mWeek = (nbWeeks % 4) + 1; // % is modulo
		var mDay = Gregorian.info(garminMomentNow, Time.FORMAT_SHORT).day_of_week;
		
		if (mPeriod == 14) { // there is no P14, so 2 options: P13W5 or next year P1W1
			var week = nbWeeksInP13(marsYear); //retrieve number of weeks in P13
			if (week == 5) { // we are in P13W5
				mPeriod = 13;
				mWeek = 5;
			} else if (week == 4) { // we are in next year
				marsYear = marsYear + 1;
				mPeriod = 1;
				mWeek = 1;
			}
		}
		var output = "P"+mPeriod+"W"+mWeek+" D"+mDay;
		return output;
	}
}
