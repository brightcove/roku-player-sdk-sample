sub init()

    m.scene = m.top.getScene()

    ' create an object to store the video metadata so we can then load it into the bcPlayer node for playback when the play button is selected
    m.videoMetadata = invalid

    ' setup the data field observer so we can then handle the type of action selected in the app menu
    m.top.observeField("data", "onData")
    
    m.background = m.top.findNode("background")
    m.title = m.top.findNode("title")
    m.duration = m.top.findNode("duration")
    m.description = m.top.findNode("description")
    m.poster = m.top.findNode("poster")
    m.poster.loadingBitmapUri = "pkg:/images/channel-poster_hd.png"
    m.thumbnail = m.top.findNode("thumbnail")
    m.thumbnail.loadingBitmapUri = "pkg:/images/channel-poster_sd.png"
    
    m.buttons = m.top.findNode("buttons")
    m.buttons.observeField("itemSelected", "onButtonSelected")
    buttonsContent = createObject("roSGNOde", "ContentNode")
    for each item in [{ id: "play", title: "Play" }, { id: "info", title: "More Info" }, { id: "favorite", title: "Add to Favorites" }, { id: "rate", title: "Rate" }]
        button = buttonsContent.createChild("ContentNode")
        button.setFields(item)
    end for
    m.buttons.visible = false
    m.buttons.content = buttonsContent
    
end sub

sub onData(ev)

    data = ev.getData() ' data => {type: "details", asset: "<brightcove-video-id>", accountID: "", policyKey: ""}

    ' Make sure that data contains the properties we need (type and asset)
    if NOT m.scene.utils.callFunc("validate", data, { type: "aa", properties: {
        type: { type: "string", empty: false },
        asset: { type: "string", empty: false },
        accountID: { type: "string", empty: false },
        policyKey: { type: "string", empty: false }
    } }) then return

    ' create the bcPlayer node instance
    m.bcPlayer = createObject("roSGNode", "bcLib:bcPlayer")

    ' Setup the common bcPlayer event observers.
    m.bcPlayer.on.observeField("close", "onPlayerClose")

    ' Setup the bcPlayer configuration fields for this particular sample.
    m.bcPlayer.setFields({
        width: 1920,
        height: 1080,
        logLevel: 4,
        credentials: {
            account_id: data.accountID
            policy_key: data.policyKey
        },
        retryOnError: false,
        ' since we're reusing the same instance of the bcPlayer node in this screen, make sure that the following close flags are set to "soft".
        ' This keeps bcPlayer internal components on standby when closing it, which means that we'll be able to use it again
        closeOnBack: "soft",
        closeOnFinished: "soft"
    })

    ' [optional] Customize Brightcove's Data Collection analytics configurations to make it easier to identify and filter this Roku SDK player events
    m.bcPlayer.analytics.playerId = "roku-sdk"
    m.bcPlayer.analytics.applicationID = "public-sample-app"
    m.bcPlayer.analytics.destination = "details/" + data.type
    m.bcPlayer.analytics.source = "menu"

    ' retrieve the video metadata through the getVideo function by disabling the autoload property
    responseNode = m.bcPlayer.callFunc("getVideo", data.asset, {
        autoload: false
    })

    if responseNode <> invalid then responseNode.observeField("response", "onVideoResponse")

end sub

sub onVideoResponse(ev)
    response = ev.getData()
    if response = invalid then return

    if response.code <> 200 then
        ' handle the error
        return
    end if

    ' Once we have the video metadata, we can fill in the Details screen components and store the metadata so we can then load it up in the bcPlayer node for playback
    
    ' To speed up the video buffering and playback start when the user presses the play button, we could:
    ' - load the video metadata into bcPlayer at this point
    ' - disable autoplay
    ' - enable prebuffer
    ' - when handling the play button select, trigger the play command

    m.videoMetadata = response.body ' get the video metadata

    'response data contains the video metadata, such as name, description, poster, etc.
    m.thumbnail.uri = m.videoMetadata.thumbnail
    m.poster.uri = m.videoMetadata.poster
    m.title.text = m.videoMetadata.name
    m.description.text = m.videoMetadata.description

    ' format the video duration provided into hh:mm:ss
    secs = m.videoMetadata.duration / 1000  ' convert it to seconds
    hh = (int(secs / 3600)).toStr()         ' calculate the number of hours
    mm = (int(secs / 60) MOD 60).toStr()    ' calculate the number of minutes
    ss = (secs MOD 60).toStr()              ' calculate the number of seconds
    m.duration.text = String(2 - hh.Len(), "0") + hh + ":" + String(2 - mm.Len(), "0") + mm + ":" + String(2 - ss.Len(), "0") + ss ' add the values together into the hh:mm:ss format

    ' adjust the background rectangle opacity so we can see the video poster in the background
    m.background.opacity = 0.8

    m.buttons.visible = true
    m.buttons.setFocus(true)

end sub

' handles the Details screen menu buttons selection
' In this sample we'll only handle the "play" button selection to open up bcPlayer
sub onButtonSelected(ev)

    if m.videoMetadata = invalid then return

    selected = ev.getData()
    button = ev.getRoSGNode().content.getChild(selected)
    if button = invalid then return

    if button.id = "play" then

        ' handle the play button selection

        ' add the bcPlayer node to the scene graph
        m.top.appendChild(m.bcPlayer) 

        ' load the video metadata into the bcPlayer node so it starts playing the video automatically
        m.bcPlayer.callFunc("load", m.videoMetadata)

        ' set the focus into the bcPlayer node
        m.bcPlayer.setFocus(true)

    end if

end sub

' Handles bcPlayer close event.
' Since we're doing a soft close, all we need to do is remove bcPlayer node from the screen and update the focus
sub onPlayerClose(ev)

    m.top.removeChild(m.bcPlayer)

    m.buttons.setFocus(true)

end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
    if key = "back" then
        if press then m.top.close = true
        handled = true
    end if
    return handled
end function