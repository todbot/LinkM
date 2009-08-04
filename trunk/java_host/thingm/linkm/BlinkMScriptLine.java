/**
 *
 */

package thingm.linkm;

/**
 * Java data struct representation of a BlinkM script line
 * also includes string rendering
 */
public class BlinkMScriptLine {
  int dur = 0xff;
  char cmd = (char)0x00;   // indicates uninit'd line
  int  arg1,arg2,arg3;
  String comment;
  
  public BlinkMScriptLine() {
  }

  public BlinkMScriptLine( int d, char c, int a1, int a2, int a3 ) {
    dur = d;
    cmd = c;
    arg1 = a1; 
    arg2 = a2;
    arg3 = a3;
  }
  
  public BlinkMScriptLine( String l ) { 

  }

  /**
   *  "construct" from a byte array.  could also do other error checking here
   */
  public boolean fromByteArray(byte[] ba) {
    if( ba==null || ba.length != 5 ) return false;
    dur  = ba[0] & 0xff;
    cmd  = (char)(ba[1] & 0xff);
    arg1 = ba[2] & 0xff;
    arg2 = ba[3] & 0xff;
    arg3 = ba[4] & 0xff;  // because byte is stupidly signed
    return true;
  }
  
  public void addComment(String s) {
    comment = s;
  }
  
  public String toStringSimple() {
    return "{"+dur+", {'"+cmd+"',"+arg1+","+arg2+","+arg3+"}},";
  }
  public String toFormattedString() {
    return toString();
  }
  // this seems pretty inefficient with all the string cats
  public String toString() {
    String s;
    if( cmd==0x00 && comment !=null ) {
      s = comment;
    }
    else {
      String cmdstr = "'"+cmd+"'";
      if( cmd < ' ' || cmd > '~' )  // outside printable ascii space
        cmdstr = makeGoodHexString(cmd);
        
      s = "{"+dur+", {"+cmdstr+",";
      if( cmd=='n'||cmd=='c'||cmd=='C'||cmd=='h'||cmd=='H' ) {
        s += makeGoodHexString(arg1) +","+
          makeGoodHexString(arg2) +","+
          makeGoodHexString(arg3) +"}},";
      }
      else 
        s += arg1+","+arg2+","+arg3+"}},";
      if( comment!=null ) s += "\t// "+comment;
    }
      return s;
  }
  // convert a byte properly to a hex string
  // why does Java number formatting still suck?
  public String makeGoodHexString(int b) {
    String s = Integer.toHexString(b);
    if( s.length() == 1 ) 
      return "0x0"+s;
    return "0x"+s;
  }
  

}
