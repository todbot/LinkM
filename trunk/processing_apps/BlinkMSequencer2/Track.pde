// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class Track {

  String label;
  int numSlices;

  Color[] slices;
  boolean[] selects;

  boolean isLoop = true;           // loop or no loop
  boolean active = false;

  int blinkmaddr = -1;  // default address, means "not configured"
  
  /**
   * @param numSlices number of slices in a track
   */
  public Track(int numSlices, Color cEmpty ) {
    this.numSlices = numSlices;
    this.active = false;
    this.isLoop = true;

    slices = new Color[numSlices];
    selects = new boolean[numSlices];
    
    for( int i=0; i<numSlices; i++ ) {
      slices[i] = cEmpty; // default color
      selects[i] = false;
    }

  }

  /**
   * 
   */
  public void copy(Track track) {
    this.label      = track.label;
    this.numSlices  = track.numSlices;
    this.isLoop     = track.isLoop;
    this.active     = track.active;
    this.blinkmaddr = track.blinkmaddr;

    for( int i=0; i<numSlices; i++ ) {
      slices[i]  = track.slices[i];
      selects[i] = track.selects[i];
    }
  }

  /**
   * 
   */
  public void copySlices(Track track) {
    int start = 0;
    int end = numSlices;
    int dest_start = 0;
    int dest_end = numSlices;
    for( int i=0; i<numSlices; i++ ) { 
      if( track.selects[i] ) 
        end = i;
      if( track.selects[numSlices-i-1] )
        start = numSlices-i-1;
      if( this.selects[numSlices-i-1] )
        dest_start = numSlices-i-1;
    }
    int range = end-start;
    dest_end = dest_start + range;
    if( dest_end > numSlices ) dest_end = numSlices-1;

    //println("copy "+start+"-"+end+" to "+dest_start+"-"+dest_end);
        
    for( int i=dest_start,j=start; i<dest_end+1; i++,j++ ) {
      slices[i]  = track.slices[j];
      selects[i] = track.selects[j];
    }
  }

  /**
   *
   */
  public void erase() {
    this.active = false;
    for( int i=0; i<numSlices; i++) {
      this.slices[i] = cEmpty;
      this.selects[i] = false;
    }
  }

} 


