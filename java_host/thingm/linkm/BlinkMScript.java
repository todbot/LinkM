/**
 *
 * This is basically just a wrapper around ArrayList<BlinkMScriptLine>
 * that is shorter to type than the above and also because Java really
 * doesn't have typedefs.
 *
 */


package thingm.linkm;

import java.util.ArrayList;


public class BlinkMScript {
  ArrayList<BlinkMScriptLine> scriptLines;
  

  public BlinkMScript() {
    scriptLines = new ArrayList<BlinkMScriptLine>();
  }

  public BlinkMScript( ArrayList<BlinkMScriptLine> sl ) {
    scriptLines = sl;
  }

  /**
   * Get length of script in lines
   */
  public int length() {
    return scriptLines.size();
  }
  
  /**
   * Get a particular BlinkMScriptLine
   */
  public BlinkMScriptLine get(int i) {
    return scriptLines.get(i);
  }
  /**
   * Add a BlinkMScriptLine to the script
   */
  public void add( BlinkMScriptLine line) {
    scriptLines.add(line);
  }

  /**
   * Return all BlinkMScriptLines, as an ArrayList
   */
  public ArrayList<BlinkMScriptLine> getScriptLines() {
    return scriptLines;
  }

  public void setScriptLines( ArrayList<BlinkMScriptLine> sl ) {
    scriptLines = sl;
  }

  /**
   * Utility: remove null/comment scriptLines
   */
  public BlinkMScript trimComments() {
    BlinkMScript newscript = new BlinkMScript();
    BlinkMScriptLine line;
    for( int i=0; i< length(); i++) { 
      line = get(i);
      if( line.commentOnly() ) {
        // comment-only line, skip
      } else { 
        newscript.add(line);
      }
    }
    return newscript;
  }

  /**
   * 'serialize' to String
   */
  public String toString() {
    return toString(false);
  }

  public String toString(boolean withLineNums ) { 
    String str = ""; //"{\n";
    BlinkMScriptLine line;
    for( int i=0; i< length(); i++ ) {
      line = get(i);
      //str += ((withLineNums)?i:"")+"\t"+ line.toFormattedString() +"\n";
      str += ((withLineNums)?(i+"\t"):"")+ line.toFormattedString() +"\n";
    }
    //str += "}\n";
    return str;
    
  }
  
}

