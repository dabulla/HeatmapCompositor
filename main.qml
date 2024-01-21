import QtGraphicalEffects 1.15
import QtQml.Models 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("Heatmap")
    property string filename: "heat.png"
    Material.theme: Material.Dark
    Material.accent: Material.Orange
    color: Material.backgroundColor
    property int downsampleResolution: resSwitch.checked ? 32 : Math.min(elemImgSrcForSize.paintedWidth, 256)
    MouseArea {
        id: windowMouse
        hoverEnabled: true
        anchors.fill: parent
        onPositionChanged: hideUserinterface.mouseMoved()
        property real blendOffsetX: 0.5/elemImg.texSize.width
        property real blendOffsetY: -0.5/elemImg.texSize.height
        onMouseXChanged: if(updateMouse.checked && windowMouse.containsPress)
                             blendOffsetX = 0.5*(windowMouse.mouseX/windowMouse.width-0.5)
        onMouseYChanged: if(updateMouse.checked && windowMouse.containsPress)
                             blendOffsetY = 0.5*(windowMouse.mouseY/windowMouse.height-0.5)
        z: 100
    }
    Timer
    {
        id: hideUserinterface
        repeat: false
        interval: 2000
        onTriggered: userInterface.opacity = fadeUi.checked
        function mouseMoved()
        {
            userInterface.opacity = 1
            restart()
        }
    }

    Item {
        id: userInterface
        z: 200
        anchors.fill: parent
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        GridLayout {
            anchors.top: parent.top
            anchors.right: parent.right
            columns: 2
            rows: 2
            Label { text: "Show UI" }
            Switch { id: fadeUi }
            Label { text: "Update Mouse" }
            Switch { id: updateMouse }
            Label { text: "Resolution" }
            Switch { id: resSwitch }
            Label { text: "Max Intens" }
            Switch { id: maxIntensSwitch }
        }
        Rectangle {
            border.color: "black"
            border.width: 1
            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: 5
            }
            width: 10
            height: 300
            gradient: rectGrad
        }
        ListView {
            id: view
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: 2
            }
            width: 240

            model: ObjectModel {
                id: visualModel
                ImageFilterOption {
                    id: itemImg
                    name: "Load Image"
                    enableEffect: true
                    enabled: false
                    property var img: elemImg
                }
                ImageFilterOption {
                    id: itemTrans
                    name: "Transferfunction"
                    property var img: elemTrans
                }
                ImageFilterOption {
                    id: itemUpscale
                    name: "Upsampling"
                    property var img: elemUpscale
                }
                ImageFilterOption {
                    id: itemBlend
                    name: "Blend"
                    property var img: elemBlend
                }
                function updateEffects()
                {
                    for(let i=1 ; i<visualModel.count ; i++)
                    {
                        let item =visualModel.get(i).img
                        item.prev = visualModel.get(i-1).img
                        item.z = i
                    }
                }
                Component.onCompleted: visualModel.updateEffects()
            }

            spacing: 4
            cacheBuffer: 50
            clip: true
            interactive: false
        }
    }

    LinearGradient {
        id: gradient
        width: 1
        height: 256
        gradient: Gradient {
            id: rectGrad
            GradientStop { position: 0.0; color: "black" }
            GradientStop { position: 0.2; color: "blue" }
            GradientStop { position: 0.4; color: "purple" }
            GradientStop { position: 0.6; color: "red" }
            GradientStop { position: 0.8; color: "yellow" }
            GradientStop { position: 1.0; color: "white" }
        }
    }
    ShaderEffectSource {
        id: gradTex
        sourceItem: gradient
        hideSource: true
    }
    Rectangle {
        id: blackBackground
        anchors.fill: parent
        color: "black"
    }
    ShaderEffectSource {
        property var texSize: elemImg.texSize
        id: blackTex
        sourceItem: blackBackground
        hideSource: false
    }
    property real effectWidth: elemImgSrc.paintedWidth
    property real effectHeight: elemImgSrc.paintedHeight
    Image {
        id: elemImgSrcForSize
        visible: false
        anchors.fill: parent
        source: window.filename
        fillMode: Image.PreserveAspectFit
    }
    Image {
        id: elemImgSrc
        layer.textureSize: elemImg.texSize
        layer.enabled: true
        layer.smooth: true
        width: elemImgSrcForSize.paintedWidth
        height: elemImgSrcForSize.paintedHeight
        visible: false
        source: window.filename
    }
    Colorize {
        // Qt.size(elemImgSrc.height, elemImgSrc.width)//
        property var texSize: Qt.size(window.downsampleResolution, window.downsampleResolution*(elemImgSrc.height/elemImgSrc.width))
        property var output: visible ? elemImg : blackTex
        property var prev: elemImg
        layer.textureSize: texSize
        layer.enabled: true
        layer.smooth: true
        visible: itemImg.enableEffect
        id: elemImg
        source: elemImgSrc
        hue: 0.0
        saturation: 0.0
        lightness: 0.0
        anchors.centerIn: parent
        width: effectWidth
        height: effectHeight
    }
    MyEffect {
        id: elemTrans
        myItem: itemTrans
        prev: elemImg
        property variant grad: gradTex
        fragmentShader: "
            varying highp vec2 coord;
            uniform sampler2D src;
            uniform sampler2D grad;
            uniform lowp float qt_Opacity;
            void main() {
                lowp vec4 tex = texture2D(src, coord);
                lowp vec4 col = texture2D(grad, vec2(0.0,tex.r));
                gl_FragColor = vec4(col.rgb, tex.a) * qt_Opacity;
            }"
    }
    MyEffect {
        id: elemUpscale
        myItem: itemUpscale
        prev: elemTrans
        texSize: Qt.size(window.effectWidth, window.effectHeight)
        fragmentShader: "
            varying highp vec2 coord;
            uniform sampler2D src;
            uniform lowp float qt_Opacity;
            void main() {
                lowp vec4 tex = texture2D(src, coord);
                gl_FragColor = tex * qt_Opacity;
            }"
    }
    MyEffect {
        id: elemBlend
        myItem: itemBlend
        prev: elemUpscale
        property vector2d off: Qt.vector2d(windowMouse.blendOffsetX, windowMouse.blendOffsetY)
        property bool maxIntens: maxIntensSwitch.checked
        fragmentShader: "
            varying highp vec2 coord;
            uniform sampler2D src;
            uniform highp vec2 off;
            uniform bool maxIntens;
            uniform lowp float qt_Opacity;
            void main() {
                lowp vec4 tex1 = texture2D(src, coord);
                lowp vec4 tex2 = texture2D(src, coord - off);
                if(maxIntens) {
                        if(length(tex1) > length(tex2))
                            gl_FragColor = tex1 * qt_Opacity;
                        else
                            gl_FragColor = tex2 * qt_Opacity;
                } else {
                    gl_FragColor = (tex1 + tex2) * 0.5 * qt_Opacity;
                }
            }"
    }
    component ImageFilterOption: DraggableItem {
        id: filterRoot
        property string name
        property bool enableEffect: false
        RowLayout {
            id: row
            anchors { fill: parent; margins: 2 }
            height: effectSwitch.height
            Item {
                id: hamburger
                property color stripeColor: "lightGray"
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                Layout.preferredWidth: effectSwitch.height
                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: parent.height*0.2
                    anchors.bottomMargin: parent.height*0.3
                    anchors.leftMargin: parent.height*0.2
                    anchors.rightMargin: parent.height*0.2
                    Repeater {
                        model: filterRoot.enabled ? 3 : 0
                        Rectangle {
                            height: 3
                            radius: 3
                            Layout.fillWidth: true
                            color: Qt.darker(hamburger.stripeColor);
                        }
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignVCenter
                text:  name
            }
            Item {
                Layout.fillWidth: true
            }
            Switch {
                Layout.alignment: Qt.AlignVCenter
                id: effectSwitch
                checked: enableEffect
                onCheckedChanged: enableEffect = checked
            }
        }
    }
}
