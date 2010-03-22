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
  public void erase() {
    this.active = false;
    for( int i=0; i<numSlices; i++) {
      this.slices[i] = cEmpty;
      this.selects[i] = false;
    }
  }

} 


