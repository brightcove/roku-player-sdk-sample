sub init()

    m.scene = m.top.getScene()

    ' set the data field observer so we can then handle the sample selected in the app menu
    m.top.observeField("data", "onData")

end sub

' Handle the sample selected in the app menu
' check the data.json file for the list of customSamples supported data values
sub onData(ev)

    data = ev.getData() ' data => {type: ""}

    ' Make sure that data contains the properties we need (type)
    if NOT m.scene.utils.callFunc("validate", data, { type: "aa", properties: {
        type: { type: "string", empty: false }
    } }) then return

    ' create a bcPlayer node instance
    m.bcPlayer = createObject("roSGNode", "bcLib:bcPlayer")

    ' Setup the bcPlayer event observers.
    m.bcPlayer.on.observeField("close", "onClose") ' The close event is essential to detect the bcPlayer node closure and then close the screen

    ' [optional] Customize Brightcove's Data Collection analytics configurations to make it easier to identify and filter this Roku SDK player events
    m.bcPlayer.analytics.playerId = "roku-sdk"
    m.bcPlayer.analytics.applicationID = "public-sample-app"
    m.bcPlayer.analytics.destination = "custom/" + data.type
    m.bcPlayer.analytics.source = "menu"

    if data.type = "basic" then

        ' ------------------------------------------------
        ' Simple video playback
        ' ------------------------------------------------

        ' make sure we have a valid metadata object
        metadata = data.metadata
        if NOT m.scene.utils.callFunc("isAA", metadata) then return

        ' Setup the bcPlayer configuration fields.
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' load the video metadata using the "loadCustom" bcPlayer function and start playback
        m.bcPlayer.callFunc("loadCustom", metadata)

    else if data.type = "basic_csai" then

        ' ------------------------------------------------
        ' CSAI video playback
        ' ------------------------------------------------

        ' make sure we have a valid metadata object
        metadata = data.metadata
        if NOT m.scene.utils.callFunc("isAA", metadata) then return

        ' Setup the bcPlayer configuration fields.
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            retryOnError: false
        })

        m.bcPlayer.csai.enabled = true ' Enable CSAI video playback in the bcPlayer node
        m.bcPlayer.csai.observeField("event", "onCSAIEvent") ' setup the CSAI event observer to capture CSAI specific events
        
        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' load the video metadata using the "loadCustom" bcPlayer function and start playback
        m.bcPlayer.callFunc("loadCustom", metadata)

    else if data.type = "playlist" then

        ' ------------------------------------------------
        ' Playlist with CSAI playback
        ' ------------------------------------------------

        ' make sure we have a valid metadata object
        metadata = data.metadata
        if NOT m.scene.utils.callFunc("isArray", metadata) then return

        ' Setup the bcPlayer configuration fields.
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            retryOnError: false
        })

        ' setup the autoPlayNext and loop flags (both disabled by default), which might be useful when playing playlists
        m.bcPlayer.playback.autoPlayNext = true
        m.bcPlayer.playback.loop = true

        m.bcPlayer.csai.enabled = true ' Enable CSAI video playback in the bcPlayer node
        m.bcPlayer.csai.observeField("event", "onCSAIEvent") ' setup the CSAI event observer to capture CSAI specific events

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' load the video metadata using the "loadCustom" bcPlayer function and start playing the video specified by the "autoplay" property
        m.bcPlayer.callFunc("loadCustom", metadata, {
            autoplay: 2             ' specify the index of the video that should start playing (or prebuffering if the prebuffer property is enabled). In this case, play the video at index 2.
            ' prebuffer: false      ' specify if it should play or prebuffer the video at the position indicated by the autoplay property
            ' position: "replace"   ' specify where the new content should be placed if there's already any existing content
        })

    end if

end sub

' Handles CSAI specific events
sub onCSAIEvent(ev)

    data = ev.getData()

    print "[customSamples] onCSAIEvent() data: " data

end sub


' handles the bcPlayer close event
' we should close the screen when the bcPlayer node is closed
sub onClose(ev)

    closeType = ev.getData() ' "hard" / "soft"

    ' clean up the bcPlayer observers and other objects before closing the screen
    m.bcPlayer.csai.unobserveField("event")
    m.bcPlayer.ssai.unobserveField("event")
    m.bcPlayer.on.unobserveField("close")
    m.top.removeChild(m.bcPlayer)
    m.bcPlayer = invalid

    ' set the close field to close the screen (this action is then handled by the onScreenClose() function in the MainScene)
    m.top.close = true

end sub