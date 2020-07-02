import QtGraphicalEffects 1.15
import QtQuick 2.15

ShaderEffect {
    id: that
    required property var myItem
    z: myItem.ObjectModel.index
    property var prev//: {output: 0}//: visualModel.get(myItem.ObjectModel.index-1).img
    property var texSize: prev.output.texSize
    property var output: visible ? that : prev.output
    layer.textureSize: texSize
    layer.enabled: true
    layer.smooth: true
    visible: myItem.enableEffect
    anchors.centerIn: parent
    width: window.effectWidth
    height: window.effectHeight
    property variant src: prev.output
    vertexShader: "
        uniform highp mat4 qt_Matrix;
        attribute highp vec4 qt_Vertex;
        attribute highp vec2 qt_MultiTexCoord0;
        varying highp vec2 coord;
        void main() {
            coord = qt_MultiTexCoord0;
            gl_Position = qt_Matrix * qt_Vertex;
        }"
}
