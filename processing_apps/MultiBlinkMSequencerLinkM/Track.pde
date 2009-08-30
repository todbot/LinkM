// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class Track {

  int numSlices;

  Color[] slices;
  boolean[] selects;

  boolean isLoop = true;           // loop or no loop
  boolean active = false;

  int blinkmaddr = -1;  // default address, means "not configured"
  
  /**
   * @param numSlices number of slices in a track
   */
  public Track(int numSlices ) {
    this.numSlices = numSlices;
    this.active = false;
    this.isLoop = true;

    slices = new Color[numSlices];
    selects = new boolean[numSlices];
    
    for( int i=0; i<numSlices; i++ ) {
      slices[i] = tlDarkGray; // default color
      selects[i] = false;
    }

  }



} 


