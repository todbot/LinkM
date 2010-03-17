// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
class Log {
  int level = 0;

  public Log() {
    info("Log started");
  }  
  public void setLevel(int l) {
    level = l;
  }

  // shortcut call to debug() method
  public void d(Object o) {
    debug(o);
  }  

  public void debug(Object o) {
    if(level>0) println("DEBUG: " + o.toString());
  }

  public void info(Object o) {
    println("INFO:  " + o.toString());
  }

  public void warn(Object o) {
    println("WARN:  " + o.toString());
  }

  // shortcut call to error() method
  public void err(Object o) {
    error(o);
  }

  public void error(Object o) {
    println("ERROR:  " + o.toString());
  }

}
