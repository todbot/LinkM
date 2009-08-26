/**
 *
 */
public class TimeTrack { 
  private int x, y, w, h;
  private int spacerWidth;
  private int scrubHeight;
  public TimeSlice[] timeSlices = new TimeSlice[numSlices];
  boolean active;

  public TimeTrack(int x, int y, int w, int h, int sw) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.spacerWidth = sw;
    this.active = false;

    // initialize and add numSlices TimeSlice objects
    // draw guide rects
    int xStep = (this.w / numSlices) - spacerWidth;
    int xRemaining = this.w % numSlices - spacerWidth;
    int xCurr = x;
    for (int i=1; i<numSlices+1; i++) {
      TimeSlice ts = new TimeSlice(xCurr, y+1, xStep, h);
      /*
      if (i%8 == 0) 
        ts.isTicked = true; 
      */
      xCurr += xStep + spacerWidth;
      timeSlices[i-1] = ts;
    }
  }

}
