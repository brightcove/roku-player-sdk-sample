Library "Roku_Ads.brs"

sub init()

    m.top.backgroundColor = "#ffffff"
    m.top.backgroundURI = ""

    ' read the data.json file contents and turn it into an AssocArray object so we can access its contents to startup and setup the app
    m.appData = ParseJson(ReadAsciifile("pkg:/data.json"))
    if m.appData = invalid then
        print "ERROR: Couldn't read the 'data.json' file"
        return
    end if

    ' Mapping object for the app menu and screen contents. We'll use this object to build the menu buttons and control their select action
    m.appContent = m.appData.content

    ' Setup the ComponentLibrary node to load up the Roku SDK component library and an observer for the "loadStatus" field so that we can follow the load process
    ' The load process initiates as soon as the URI field is set
    m.bcLib = m.top.findNode("bcLib")
    m.bcLib.observeField("loadStatus", "onLoadStatus")
    m.bcLib.uri = m.appData.sdkUrl

    m.header = m.top.findNode("header")
    m.header.setFields({
        color: "#000000"
        height: 1080
        width: 640
    })

    m.logo = m.top.findNode("logo")
    m.logo.setFields({
        width: 448
        height: 222.6
        uri: "pkg:/images/bc_roku-sdk_logo.png"
        translation: [96, 54]
    })

    ' store some basic values to make menu size and positioning calculations easier
    buttonsWidth = 280
    buttonsHeight = 72
    buttonsSpacing = 18
    menuWidth = buttonsWidth * 2 + buttonsSpacing
    
    ' Setup the menu configurations.
    ' Although we're only using a single Rowlist component for the manu buttons, keep in mind that the first row of button behave like tabs
    m.menuBar = m.top.findNode("menuBar")
    m.menuBar.observeField("rowItemSelected", "onMenuSelected")
    m.menuBar.setFields({
        itemComponentName: "MenuItem"
        itemSize: [menuWidth, buttonsHeight]
        rowItemSize: [[buttonsWidth, buttonsHeight], [menuWidth, buttonsHeight]]
        numRows: 10
        rowHeights: [buttonsHeight]
        rowSpacings: [42]
        itemSpacing: [0, 16]
        rowItemSpacing: [[buttonsSpacing, 0], [0, 0]]
        focusXOffset: [0]
        showRowLabel: [false]
        showRowCounter: [false]
        rowFocusAnimationStyle: "floatingFocus"
        vertFocusAnimationStyle: "floatingFocus"
        focusBitmapBlendColor: "#4EA9D1"
        translation: [(1280 - menuWidth) / 2 + m.header.width, 80]
        itemClippingRect: [0, -80, menuWidth, 1080]
    })

end sub

sub onLoadStatus(ev)
    status = ev.getData()
    if status = "ready" then

        ' bcLib was loaded successfully and all its components are now accessible

        ' create an instance of the Utils node so we can easily access it anywhere in the app
        m.top.utils = CreateObject("roSGNode", "bcLib:Utils")

        ' create and setup the menu content based on the m.appContent mapping
        menuContent = CreateObject("roSGNode", "ContentNode")
        menuRowContent = menuContent.createChild("ContentNode")
        menuRowContent.addFields({ active: "none" }) ' the active field tracks the selected tab

        for each item in m.appContent.Items()
            button = menuRowContent.createChild("ContentNode")
            button.setFields({ id: item.key, title: item.value.title })
        end for

        m.menuBar.content = menuContent
        m.menuBar.setFocus(true)

        ' simulate a menu button press to load up the initial set of menu buttons
        onMenuSelected({
            menu: m.menuBar
            getData: function()
                return [0, 0]
            end function
            getRoSGNode: function()
                return m.menu
            end function
        })

    else if status = "loading" then
        ' bcLib package is currently being loaded
        
    else if status = "failed" then
        ' Something went wrong with the bcLib download/load process.
        ' Please check if the package URL was properly set.
    end if
end sub

sub onMenuSelected(ev)

    data = ev.getData()
    selectedRow = data[0]
    selectedItem = data[1]

    menu = ev.getRoSGNode()
    menuContent = menu.content

    if menuContent = invalid then return
    menuRow = menuContent.getChild(selectedRow)
    if menuRow = invalid then return

    selectedButton = menuRow.getChild(selectedItem)
    if selectedButton = invalid then return

    ' handle the tabs selection
    if selectedRow = 0 then 

        ' if the same menu button was selected we should ignore it
        if menuRow.active = selectedButton.id then return
        
        ' retrieve the selected button contents from the m.appContent mapping
        buttons = m.appContent[selectedButton.id]

        ' to be safe, ignore if the button contents can't be found
        if NOT m.top.utils.callFunc("isArray", buttons?.content) then return

        ' since we're rebuilding the menu, we'll first remove any existing content, other than the first row of buttons (aka tabs)
        menuRows = menuContent.getChildCount()
        if menuRows > 1 then menuContent.removeChildrenIndex(menuRows - 1, 1)

        ' setup the new buttons ContentNodes based on the m.appContent mapping
        for each item in buttons.content

            ' use the Roku SDK Utils.validate() function to make sure we have everything we need to setup the button
            if m.top.utils.callFunc("validate", item, { 
                type: "aa", 
                empty: false, 
                properties: {
                    title: { type: "string", empty: false }
                    screen: { type: "string", empty: false }
                    data: { type: "aa", empty: false }
                }
            }) then
                
                buttonID = LCASE(item.title).replace(" ", "-")

                ' Create the button ContentNode nodes
                ' Since we're using a RowList, we need a ContentNode for the row (rowContent) and another ContentNode for the actual button within the row (buttonContent)
                rowContent = CreateObject("roSGNode", "ContentNode")
                buttonContent = rowContent.createChild("ContentNode")

                ' store the "screen" and "data" properties so they can then be used in the button selected handler.
                ' SInce these are custom properties, we should use the addFields function
                buttonContent.addFields({ 
                    screen: item.screen,
                    data: item.data
                })

                ' set the button id and title properties. 
                ' Since these are native fields of the ContentNode node, we can use the setFields function
                buttonContent.setFields({
                    id: buttonID
                    title: item.title
                })

                menuContent.appendChild(rowContent)

            end if

        end for

        ' update the active button so that it can then be used to update the UI and to handle the other buttons select action
        menuRow.active = selectedButton.id

        return
    end if

    ' handle the other buttons selection

    screenComponent = selectedButton?.screen
    screenData = selectedButton?.data
    if m.top.utils.callFunc("isString", screenComponent) AND m.top.utils.callFunc("isAA", screenData) then

        ' create the screen component
        m.screen = m.top.createChild(screenComponent)
        if m.screen <> invalid then

            ' setup the close field observer so we can close the screen
            if m.screen.hasField("close") then m.screen.observeField("close", "onScreenClose")

            ' set the data screen field so it can handle the specific action
            if m.screen.hasField("data") then m.screen.data = screenData

            ' focus the screen node
            m.screen.setFocus(true)

        end if

    end if

end sub

' Handles the screens closure
sub onScreenClose(ev)

    if m.screen = invalid then return

    m.screen.unobserveField("close")

    m.top.removeChild(m.screen)
    m.screen = invalid

    m.menuBar.setFocus(true)

end sub