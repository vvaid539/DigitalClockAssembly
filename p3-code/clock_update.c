#include "clock.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// This function uses the port value to calculate the number of seconds
// from start of day. Then, it calculate the time of day broken into hours,
// minutes, seconds, and sets the AM/PM designation with 1 for AM and
// 2 for PM.
int set_tod_from_ports(tod_t *tod){
  //Checks if the TIME_OF_DAY_PORT is a reasonable number
  if(TIME_OF_DAY_PORT < 0 || TIME_OF_DAY_PORT > 24 * 60 * 60 * 16){
    return 1;
  }
  //Uses bitwise operations to find the number of seconds so far in the day
  tod->day_secs = (TIME_OF_DAY_PORT >> 4) + (1 & (TIME_OF_DAY_PORT >> 3));
  //Determines number of hours
  tod->time_hours = tod->day_secs / 3600;
  //Determines AMPM
  if(tod->time_hours < 12){
    tod->ampm = 1;
  }
  else{
    tod->ampm = 2;
  }
  //Changes hour based upon if its AM or PM
  if(tod->time_hours == 0) {
    tod->time_hours = 12;
  }else if (tod->time_hours > 12) {
    tod->time_hours -= 12;
  }
  //Determines amount of minutes of the specific hour
  tod->time_mins = (tod->day_secs % 3600) / 60;
  //Determines amount of seconds of the specific minute
  tod->time_secs = tod->day_secs % 60;
  return 0;
}

// Accepts a tod and alters the bits in the int pointed at by display
// to reflect how the LCD clock should appear.  
int set_display_from_tod(tod_t tod, int *display){
  //Checking to make sure all struct values are within reason(edge testing)
  if(tod.day_secs < 0 || tod.day_secs > 89600){
    return 1;
  }
  if(tod.time_hours > 12 || tod.time_hours < 0){
    return 1;
  }
  if(tod.time_mins > 59 || tod.time_mins < 0){
    return 1;
  }
  if(tod.time_secs > 59 || tod.time_secs < 0){
    return 1;
  }
  if(tod.ampm < 1 || tod.ampm > 2){
    return 1;
  }
  //Two bit arrays for AMPM and masks
  short masks[] = {0b1110111, 0b0100100, 0b1011101, 0b1101101, 0b0101110, 0b1101011, 0b1111011, 0b0100101, 0b1111111, 0b1101111};
  short AMPM[] = {0b10, 0b01};
  //Determines the number on the clock
  int min_ones = tod.time_mins % 10;
  int min_tens = tod.time_mins / 10;
  int min_hours_ones = tod.time_hours % 10;
  int min_hours_tens = tod.time_hours / 10;
  //Declares a state variable 
  int state = 0;
  //Determines what bits are added to state variable for AMPM requirements
  if(tod.ampm == 1){
    state = (AMPM[1] << 28) | state;
  }
  else{
    state = (AMPM[0] << 28) | state;
  }
  //Check to ensure the tenths place of the hour is not 0 ceause if so nothing should be changed
  if(min_hours_tens != 0){
    state = (masks[min_hours_tens] << 21) | state;
  }
  //Add the rest of the clock bit strings to the state variable
  state = (masks[min_hours_ones] << 14) | state;
  state = (masks[min_tens] << 7 ) | state;
  state = (masks[min_ones])| state;
  //Dereference the display variable to the state variable
  *display = state;
  return 0;
}

// Examines the TIME_OF_DAY_PORT global variable to determine hour,
// minute, and am/pm.  
int clock_update(){
  //Checks if the TIME_OF_DAY_PORT is a reasonable number
  if(TIME_OF_DAY_PORT < 0 || TIME_OF_DAY_PORT > 24 * 60 * 60 * 16){
    return 1;
  }
  //Create a struct
  tod_t tod = {}; 
  //Utilise the struct and global variables in the following two function to set time 
  set_tod_from_ports(&tod);
  set_display_from_tod(tod, &CLOCK_DISPLAY_PORT);
  return 0;
}