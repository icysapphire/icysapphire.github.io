var getPixels = require("get-pixels")

function processFrame(){
  for (i=0; i<shape[1]; i++){
	for (j=0; j<shape[2]; j++){
		// Create nxm matrix with hex codes for current frame pixels
		window.frame[i][j]= "#" +("0" + pixels.get(n,i,j,0).toString(16)).slice(-2) + ("0" +pixels.get(n,i,j,1).toString(16)).slice(-2) + ("0" +pixels.get(n,i,j,2).toString(16)).slice(-2);
	}
  }
  
  // Render matrix on the pixels
  renderFrame(shape[1],shape[2]);
  
  window.n++;
  if(window.n != window.maxn-1){
	  // Queue next frame
	  setTimeout(processFrame, (1000/framerate -10));
  } else {enableButton();}

}

getPixels(window.url, function(err, pixels) {
  if(err) {
    alert("Bad image path")
    return;
  }
  window.pixels=pixels;
  shape = pixels.shape.slice();
  
  // Number of animated frames
  window.maxn= shape[0];
  
  // Init matrix
  window.frame = [];
  
  for(i=0; i<shape[1]; i++) {
	window.frame[i] = new Array(shape[2]);
  }
  
  console.log("got pixels", pixels.shape.slice());
  
  resizeGrid(shape[2]);
  createPixels(shape[1], shape[2]);
  window.n=0;
  
  // Process first frame
  processFrame();

});
