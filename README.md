# HeatmapCompositor
Visualize the effect of changing the sequence of calculations (blending, applying transfer function and upsampling) for heatmaps. This mainly shows, that the operations are not commutative and information can be preserved by upsampling the image early.
Applying the tranfer function increases the the signals frequency, depending on transfer function itself. According to Nyquist–Shannon sampling theorem, the sampling rate must be at least twice as large as the highest frequence of the underlying signal.
Especially on sharp edges, the loss of detail becomes visible in practice.
Max intensity blending is used to reconstruct the highest values unchanged during blending. This eliminates the effect of high values/maxima and low values/minima canceling each other out during (imperfect) blending.
A lower resolution for blending on the other hand can reduce ghosting by binning the blended values together.

# Interactive Demo

Try the Qt 5.15.2 WebAssembly build (wasm) at https://dabulla.github.io/HeatmapCompositor/

Buttons on the top left can be dragged and dropped to change the order of execution. The processing order is top down. The blend step can be manipulated using the mouse (can be enabled with the option on the right side).

![alt text](https://github.com/dabulla/HeatmapCompositor/blob/master/HeatmapCompositor.png?raw=true)

UI is compatible with touch and the program can be compiled under android.

# License

heat.png is from https://github.com/MicroJoe/netbpm_gs2hm/
