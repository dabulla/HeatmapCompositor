import QtQml.Models 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Window 2.15

MouseArea {
    id: dragArea

    default property alias contents: content.children

    property bool held: false

    width: view.width
    height: row.implicitHeight

    drag.target: held ? content : undefined
    drag.axis: Drag.YAxis

    pressAndHoldInterval: 10
    onPressAndHold: {
        hideUserinterface.mouseMoved()
        held = true
    }
    onPressed: hideUserinterface.mouseMoved()
    onReleased: {
        hideUserinterface.mouseMoved()
        held = false
    }

    propagateComposedEvents: true
    Rectangle {
        id: content
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        width: dragArea.width
        height: row.implicitHeight

        color: parent.enabled ? dragArea.held ? Material.accentColor : Material.backgroundColor : Material.dialogColor
        Behavior on color { ColorAnimation { duration: 100 } }


        Drag.active: dragArea.held
        Drag.source: dragArea
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        states: State {
            when: dragArea.held

            ParentChange { target: content; parent: windowMouse }
            AnchorChanges {
                target: content
                anchors { horizontalCenter: undefined; verticalCenter: undefined }
            }
        }
    }

    DropArea {
        anchors { fill: parent; margins: 10 }
        onEntered: {
            if(dragArea.ObjectModel.index === 0) return
            visualModel.move(
                    drag.source.ObjectModel.index,
                    dragArea.ObjectModel.index)
            visualModel.updateEffects();
        }
    }
}
