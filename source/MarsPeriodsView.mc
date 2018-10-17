using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

class MarsPeriodsView extends WatchUi.View {
    var font = Graphics.FONT_LARGE;
    var longishFont = WatchUi.loadResource(Rez.Fonts.longishFont);
    var bebas_neue_book_Font = WatchUi.loadResource(Rez.Fonts.bebas_neue_book_Font);
    var bebas_neue_bold_Font = WatchUi.loadResource(Rez.Fonts.bebas_neue_bold_Font);
    var lineSpacing = Graphics.getFontHeight(bebas_neue_bold_Font);
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
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        // period
        var now = new Time.Moment(Time.now().value());
        now = now.add(new Time.Duration(System.getClockTime().timeZoneOffset)); // add timezone difference
        var viewPeriod = View.findDrawableById("MarsPeriodLabel");
        //viewPeriod.setFont(font);
        viewPeriod.setLocation(centerX, top);
        viewPeriod.setText(calendarMarsDate(now));
        
        // hour
        var todayDateTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var hourString = Lang.format("$1$",[todayDateTime.hour.format("%02d")]);
        var viewHour = View.findDrawableById("HourLabel");
        viewHour.setFont(bebas_neue_bold_Font);
        viewHour.setLocation(centerX, centerY);
        viewHour.setText(hourString);
        
        // min
        var minString = Lang.format("$1$",[todayDateTime.min.format("%02d")]);
        var viewMin = View.findDrawableById("MinLabel");
        viewMin.setFont(bebas_neue_book_Font);
        viewMin.setLocation(centerX, centerY);
        viewMin.setText(minString);
        
        
        
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
    function nbWeeksInP13(mYear) {
        var yearCurrentMoment = startDateOfMarsYear(mYear);  //get garmin moment for this year start date
        var yearNextMoment = startDateOfMarsYear(mYear + 1); //get garmin moment for next year start date
        var days12x28 = new Time.Duration(29030400); // 12 periods of 28 days times number of second in one day
        var p12Current = yearCurrentMoment.add(days12x28); //moment in this year that correspond to end of P12
        var momentDiff = yearNextMoment.subtract(p12Current); //get duration between the 2 moments (start of next year P1 minus end of P12 current year)
        var nbDays = momentDiff.value()/Gregorian.Info.SECONDS_PER_DAY; //86400 is number of seconds in one day.

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
    function startDateOfMarsYear(mYear) {
        var options = {
            :year   => mYear,
            :month  => 1,
            :day    => 1
        };
        var date = Gregorian.moment(options);
        var iDay = Gregorian.utcInfo(date, Time.FORMAT_SHORT).day_of_week; // .info() method uses localtimezone. Probably better to use .info() and deal with dst !?
                                                                           // I see one hour diff if I use .info(), meaning start of the year is 1/1/year at 1:00am
                                                                           // I've put utcInfo to compensate that hour, but this is probably wrong. Is the hour delay the dst ?
                                                                           // indeed getclockTime().dst is 3600, so one hour. Code would be:
                                                                           //Gregorian.info()
                                                                           //.add(getClocktime.dst) // add of substract? by the way .subtract() without s !
                                                                           
        //System.println(iDay);
        switch (iDay) {
            case 1:
                options = {:year => mYear, :month => 1, :day => 1};
                break;
            case 2:
                options = {:year => mYear - 1, :month => 12, :day => 31};
                break;
            case 3:
                options = {:year => mYear - 1, :month => 12, :day => 30};
                break;
            case 4:
                options = {:year => mYear - 1, :month => 12, :day => 29};
                break;
            case 5:
                options = {:year => mYear - 1, :month => 12, :day => 28};
                break;
            case 6:
                options = {:year => mYear, :month => 12, :day => 3};
                break;
            case 7:
                options = {:year => mYear, :month => 12, :day => 2};
                break;
        }
        // return a moment, but is it really in local timezone?
        return Gregorian.moment(options);
    }
    
    // function calendarMarsDate convert a garmin moment into a Mars Calendar Periodic format: PxxWyyDz
    function calendarMarsDate(garminMomentNow) {
        var date = Gregorian.utcInfo(garminMomentNow, Time.FORMAT_SHORT);
        var mYear = date.year;
        var yearStart = startDateOfMarsYear(mYear);
        
        // if now is earlier than start of the Mars year, we are in previous Mars year...
        if ( garminMomentNow.lessThan(yearStart) ) {
            mYear = mYear.toNumber() - 1;
            yearStart = startDateOfMarsYear(mYear);
        }
        
        var nbDays = garminMomentNow.subtract(yearStart).value()/86400; // 86400 is the number of seconds in one day
        var nbWeeks = nbDays.toNumber()/7;
        var mPeriod = (nbWeeks / 4) + 1;
        var mWeek = (nbWeeks % 4) + 1; // % is modulo
        var mDay = date.day_of_week;
        
        if (mPeriod == 14) { // there is no P14, so 2 options: P13W5 or next year P1W1
            var week = nbWeeksInP13(mYear); //retrieve number of weeks in P13
            if (week == 5) { // we are in P13W5
                mPeriod = 13;
                mWeek = 5;
            } else if (week == 4) { // we are in next year
                mYear = mYear + 1;
                mPeriod = 1;
                mWeek = 1;
            }
        }
        var output = "P"+mPeriod+"W"+mWeek+" D"+mDay;
        return output;
    }
}
