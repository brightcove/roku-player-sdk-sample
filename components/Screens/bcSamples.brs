sub init()

    m.scene = m.top.getScene()
    
    ' set the data field observer so we can then handle the sample selected in the app menu
    m.top.observeField("data", "onData")

end sub

' Handle the sample selected in the app menu
' check the data.json file for the list of bcSamples supported data values
sub onData(ev)

    data = ev.getData() ' data => {type: "", asset: "<brightcove-asset-id>", adConfig: "", accountID: "", policyKey: ""}

    ' Make sure that data contains the properties we need
    if NOT m.scene.utils.callFunc("validate", data, {type: "aa", properties: {
        type: {type: "string", empty: false},                           ' Identifies the sample configuration
        asset: { type: "string", empty: false },                        ' Specifies the asset (video or playlist) id
        adConfig: { type: "string", required: false, empty: false },    ' Optional. Specifies the SSAI ad_config_id or the CSAI VMAP/VAST url
        accountID: { type: "string", empty: false },                    ' Specifies the Brightcove Account ID
        policyKey: { type: "string", empty: false }                     ' Specifies the Brightcove Policy Key (be aware that some PAPI requests might require a search enabled Policy Key)
    }}) then return

    ' create the bcPlayer node instance
    m.bcPlayer = createObject("roSGNode", "bcLib:bcPlayer")

    ' Setup the common bcPlayer event observers.
    m.bcPlayer.on.observeField("close", "onClose") ' The close event is essential to detect the bcPlayer node closure so we can close the screen

    ' [optional] Customize Brightcove's Data Collection analytics configurations to make it easier to identify and filter this Roku SDK player events
    m.bcPlayer.analytics.playerId = "roku-sdk"
    m.bcPlayer.analytics.applicationID = "public-sample-app"
    m.bcPlayer.analytics.destination = "brightcove/" + data.type
    m.bcPlayer.analytics.source = "menu"

    if data.type = "vod" then

        ' ------------------------------------------------
        ' Simple Brightcove video playback
        ' ------------------------------------------------

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' retrieve the Brightcove video for playback
        ' Since we just want to load and play the video immediately, no extra setup is needed
        m.bcPlayer.callFunc("getVideo", data.asset, {
            ' params: {             ' specifies the getVideo Playback API request parameters
            '     ad_config_id: ""  ' specifies the SSAI ad config ID property. Required to playback SSAI videos.
            '     config_id: ""
            ' },
            ' autoload: true        ' specifies if the video metadata should be automatically loaded into bcPlayer for playback (true by default)
            ' autoplay: 0           ' specifies the index of the video that should start playing once the load process finishes (0 by default, plays the first video in the playlist or the only video loaded)
            ' position: "replace"   ' specifies where the new video content should be added if content is already present ("replace" by default, replaces the old content with the new one)
        })

    else if data.type = "live" then

        ' ------------------------------------------------
        ' Brightcove live stream playback
        ' ------------------------------------------------

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' retrieve the Brightcove live stream for playback
        ' Since we just want to load and play the live stream immediately, no extra setup is needed
        m.bcPlayer.callFunc("getVideo", data.asset)

    else if data.type = "ssai_vod" then

        ' ------------------------------------------------
        ' Brightcove SSAI video playback
        ' ------------------------------------------------

        m.bcPlayer.ssai.enabled = true ' Enable SSAI video playback in the bcPlayer node
        m.bcPlayer.ssai.observeField("event", "onSSAIEvent") ' setup the SSAI event observer to capture SSAI specific events

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' retrieve the Brightcove video for playback and setup the ad_config_id parameter
        m.bcPlayer.callFunc("getVideo", data.asset, {
            params: { ' specifies the getVideo Playback API request parameters
                ad_config_id: data.adConfig ' specifies the SSAI ad config ID property. Required to playback SSAI videos.
            }
        })

    else if data.type = "csai_live" then

        ' ------------------------------------------------
        ' Brightcove CSAI live stream playback
        ' ------------------------------------------------

        m.bcPlayer.csai.enabled = true ' Enable CSAI video playback in the bcPlayer node
        m.bcPlayer.csai.observeField("event", "onCSAIEvent") ' setup the CSAI event observer to capture CSAI specific events

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' retrieve the Brightcove live stream for playback
        ' Since we just want to load and play the live stream immediately, no extra setup is needed
        m.responseNode = m.bcPlayer.callFunc("getVideo", data.asset, {
            autoload: false ' disable the autoload flag so we get a response Node back
            adConfig: data.adConfig ' we can also provide custom options that will be passed over to the response.options object as is. In this case we know we'll need the adConfig to setup the video properties. Check the onPAPIResponse() function to understand where we get this data from.
        })

        ' make sure that we have a valid response Node and setup the response field observer to capture the Playback API response object
        if m.responseNode <> invalid then m.responseNode.observeField("response", "onPAPIResponse")

    else if data.type = "playlist" then

        ' ------------------------------------------------
        ' Brightcove playlist playback
        ' ------------------------------------------------

        ' setup the autoPlayNext and loop flags (both disabled by default), which might be useful when playing playlists
        m.bcPlayer.playback.autoPlayNext = true
        m.bcPlayer.playback.loop = true

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' retrieve the Brightcove playlist for playback
        ' Since we just want to load and play the playlist immediately, no extra setup is needed
        m.bcPlayer.callFunc("getPlaylist", data.asset)

    else if data.type = "ssai_playlist" then

        ' ------------------------------------------------
        ' Brightcove SSAI playlist playback
        ' ------------------------------------------------

        m.bcPlayer.ssai.enabled = true ' Enable SSAI video playback in the bcPlayer node
        m.bcPlayer.ssai.observeField("event", "onSSAIEvent") ' setup the SSAI event observer to capture SSAI specific events

        ' setup the autoPlayNext and loop flags (both disabled by default), which might be useful when playing playlists
        m.bcPlayer.playback.autoPlayNext = true
        m.bcPlayer.playback.loop = true

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' retrieve the Brightcove playlist for playback
        ' Since we just want to load and play the playlist immediately, no extra setup is needed
        m.bcPlayer.callFunc("getPlaylist", data.asset, {
            params: { ' specifies the getVideo Playback API request parameters
                ad_config_id: data.adConfig ' specifies the SSAI ad config ID property. Required to playback SSAI videos.
            }
        })

    else if data.type = "csai_vod" then

        ' ------------------------------------------------
        ' Custom load a Brightcove video and setup CSAI for playback
        ' ------------------------------------------------

        m.bcPlayer.csai.enabled = true ' Enable CSAI video playback in the bcPlayer node
        m.bcPlayer.csai.observeField("event", "onCSAIEvent") ' setup the CSAI event observer to capture CSAI specific events

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' call the getVideo function and disable the autoload flag so that it returns a response Node that we can then use to retrieve the Playback API request response
        m.responseNode = m.bcPlayer.callFunc("getVideo", data.asset, {
            autoload: false ' disable the autoload flag so we get a response Node back
            adConfig: data.adConfig ' we can also provide custom options that will be passed over to the response.options object as is. In this case we know we'll need the adConfig to setup the video properties. Check the onPAPIResponse() function to understand where we get this data from.
        })

        ' make sure that we have a valid response Node and setup the response field observer to capture the Playback API response object
        if m.responseNode <> invalid then m.responseNode.observeField("response", "onPAPIResponse")

    else if data.type = "csai_playlist" then

        ' ------------------------------------------------
        ' Custom load a Brightcove playlist and setup CSAI in one of its videos for playback
        ' ------------------------------------------------

        ' set the autoPlayNext and loop flags (both disabled by default), which might be useful when playing playlists
        m.bcPlayer.playback.autoPlayNext = true
        m.bcPlayer.playback.loop = true

        m.bcPlayer.csai.enabled = true ' Enable CSAI video playback in the bcPlayer node
        m.bcPlayer.csai.observeField("event", "onCSAIEvent") ' setup the CSAI event observer to capture CSAI specific events

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' call the getPlaylist function and disable the autoload flag so that it returns a response Node that we can then use to retrieve the Playback API request response
        m.responseNode = m.bcPlayer.callFunc("getPlaylist", data.asset, {
            autoload: false ' disable the autoload flag so we get a response Node back
            adConfig: data.adConfig ' pass the adConfig property along so we can retrieve it back in the onPAPIPlaylistResponse() function to setup CSAI in some videos
        })

        ' make sure that we have a valid response Node and setup the response field observer to capture the Playback API response object
        if m.responseNode <> invalid then m.responseNode.observeField("response", "onPAPIPlaylistResponse")

    else if data.type = "related" then

        ' ------------------------------------------------
        ' Brightcove related playlist playback
        ' ------------------------------------------------
        
        ' set the autoPlayNext and loop flags (both disabled by default), which might be useful when playing playlists
        m.bcPlayer.playback.autoPlayNext = true
        m.bcPlayer.playback.loop = true

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' retrieve the Brightcove related playlist for playback
        ' Since we just want to load and play the playlist immediately, no extra setup is needed
        m.bcPlayer.callFunc("getRelated", data.asset)

    else if data.type = "search" then

        ' ------------------------------------------------
        ' Brightcove search playlist playback
        ' ------------------------------------------------

        ' set the autoPlayNext and loop flags (both disabled by default), which might be useful when playing playlists
        m.bcPlayer.playback.autoPlayNext = true
        m.bcPlayer.playback.loop = true

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list
        m.top.appendChild(m.bcPlayer)

        ' trigger the getVideos Playback API request with a specific query to search for videos
        ' Since we just want to load and play the search results playlist immediately, no extra setup is needed
        ' In this case data.asset refers to the query we're searching for
        m.bcPlayer.callFunc("getVideos", data.asset)

    else if data.type = "bcapi_load" then

        ' ------------------------------------------------
        ' Retrieve a Brightcove video through the bcAPI node and then load it into bcPlayer for playback
        ' ------------------------------------------------

        ' Setup the bcPlayer configuration fields for this particular sample. 
        ' Since we're playing Brightcove content, make sure that the Brightcove account credentials are properly set
        m.bcPlayer.setFields({
            width: 1920,
            height: 1080,
            logLevel: 4,
            credentials: {
                account_id: data.accountID
                policy_key: data.policyKey
            },
            retryOnError: false
        })

        ' add the bcPlayer node to the screen node tree list (this step could be executed later when we have the API response)
        m.top.appendChild(m.bcPlayer)

        ' for a better visual experience show the bcPlayer loading spinner while waiting for the API response
        m.bcPlayer.loading = true

        ' initialize the bcAPI node instance. Keep in mind that the bcAPI node is a Task node
        m.bcAPI = createObject("roSGNode", "bcLib:bcAPI")

        ' setup the bcAPI configurations and start running the Task (make sure that the configurations are all set before triggering the 'control = "run"')
        m.bcAPI.setFields({
            logger: m.bcPlayer.callFunc("getLogger"), ' use the same bcPlayer logger in bcAPI
            credentials: m.bcPlayer.credentials ' setup Brightcove credentials. SInce we've already set them up in the bcPlayer node, we can just use the same value
            control: "run" ' once everything's ready, run the bcAPI Task
        })

        ' setup the response observers. There are two different ways to retrieve the response from the bcAPI Task:

        '       1 - observe the bcAPI "response" field. If no response node is provided within the request data, all responses are set into the response field.
        '       Keep in mind that if there are multiple requests executed in the same bcAPI node, all responses are set into the bcAPI "response" field. 
        '       In this case it's possible to differenciate them throught the response.id property.
        ' -----------------------------------------------------------------------
        ' m.bcAPI.observeField("response", "onAPIResponse")
        ' -----------------------------------------------------------------------
        
        '       2 - create a response node, make sure it contains a "response" AssociativeArray field and setup an observer on this same field.
        '       Then provide the response node in the request options. The bcAPI will send the API response into the response node provided.
        ' -----------------------------------------------------------------------
        m.responseNode = createObject("roSGNode", "Node")
        m.responseNode.addFields({ response: {} })
        m.responseNode.observeField("response", "onAPIResponse")
        ' -----------------------------------------------------------------------

        ' trigger the Playback API getVideo request
        m.bcAPI.getVideo = { 
            id: data.asset,         ' Brightcove video ID
            node: m.responseNode    ' response Node to retrieve the response data. Remove this property to use the bcAPI response field instead (option 1 above) 
            ' params: {             ' optional request parameters, not required for this sample
            '     ad_config_id: "", 
            '     config_id: ""
            ' }
        }

    end if

end sub

' Handles SSAI specific events
sub onSSAIEvent(ev)

    data = ev.getData()

    print "[bcSamples] onSSAIEvent() data: " data

end sub

' Handles CSAI specific events
sub onCSAIEvent(ev)

    data = ev.getData()

    print "[bcSamples] onCSAIEvent() data: " data

end sub

' Handles custom video load process
sub onPAPIResponse(ev)

    response = ev.getData()
    print "[bcSamples] onPAPIResponse() response: " response

    ' clear the m.responseNode node as it won't be needed anymore
    if m.responseNode <> invalid then
        m.responseNode.unobserveField("response")
        m.responseNode = invalid
    end if

    if response.code = 200 then

        ' the video metadata is located in the response.body property
        metadata = response.body

        ' edit the "metadata" object here, before loading it up into bcPlayer for playback

        ' retrieve the adConfig we provided in the getVideo function. Custom properties are passed as is to the response object and can be found in the "options" property.
        adConfig = response.options?.adConfig
        if m.scene.utils.callFunc("isString", adConfig) then 

            ' to setup CSAI in a video, we need to setup the adsData property into the video metadata
            metadata.adsData = {    ' adsData should be an AssociativeArray object
                type: "csai",       ' specifies that this is a CSAI enabled video
                vmap: adConfig,     ' provide the VAST/VMAP file URL
            }

        end if

        ' load the updated metadata into bcPlayer and start playback
        m.bcPlayer.callFunc("load", metadata)

        return
    end if

    ' in case of a failed request, when autoload is disabled, the error must be handled manually

end sub

' Handles custom playlist with CSAI load process
sub onPAPIPlaylistResponse(ev)

    response = ev.getData()
    print "[bcSamples] onPAPIPlaylistResponse() response: " response

    ' clear the m.responseNode node as it won't be needed anymore
    if m.responseNode <> invalid then
        m.responseNode.unobserveField("response")
        m.responseNode = invalid
    end if

    if response.code = 200 then

        ' the playlist metadata is located in the response.body property
        metadata = response.body

        ' edit the "metadata" object here, before loading it up into bcPlayer for playback

        videos = metadata?.videos

        ' use the Utils isArray function to make sure that this playlist contains videos
        if m.scene.utils.callFunc("isArray", videos) AND videos.count() > 0 then

            ' make sure that the adConfig property is available. Custom properties are passed as is to the response object and can be found in the "options" property.
            adConfig = response.options?.adConfig
            if m.scene.utils.callFunc("isString", adConfig) then

                ' as an example, we'll setup CSAI in the video at index 1 of the playlist
                videos[1].adsData = {   ' adsData should be an AssociativeArray object
                    type: "csai",       ' specifies that this is a CSAI enabled video
                    vmap: adConfig,     ' provide the VAST/VMAP document URL
                }

            end if

            ' load the updated metadata into bcPlayer and start playback
            m.bcPlayer.callFunc("load", metadata)

        end if

        return
    end if

    ' in case of a failed request, when autoload is disabled, the error must be handled manually

end sub

sub onAPIResponse(ev)

    response = ev.getData()

    ' the "response.id" property can be used to filter between different API requests

    m.responseNode.unobserveField("response")
    m.responseNode = invalid

    if response.code = 200 then

        ' the video metadata is located in the response.body property
        metadata = response.body

        ' edit the "metadata" object here, before loading it up into bcPlayer for playback

        ' load the video metadata into bcPlayer and start playback
        m.bcPlayer.callFunc("load", metadata)

        return
    end if

    ' in case of a failed request the error must be handled manually

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
