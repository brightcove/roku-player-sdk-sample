sub init()
    
    m.label = m.top.findNode("label")
    m.background = m.top.findNode("background")
    m.rowContent = invalid

    m.top.observeField("itemContent", "onItemContent")
    m.top.observeField("active", "onActive")
    m.top.observeField("width", "onSize")
    m.top.observeField("height", "onSize")

end sub

sub onItemContent(ev)

    data = ev.getData()

    title = ""
    isTab = (m.top.rowIndex = 0) ' first row buttons should behave and look like tabs
    buttonID = ""

    if data <> invalid then

        title = data.title
        
        if m.rowContent = invalid then m.rowContent = data.getParent()

        buttonID = data.id

    else 

        if m.rowContent <> invalid then m.rowContent.unobserveField("active")

    end if
        
    m.label.text = title

    if isTab then
        m.background.setFields({
            color: "#F76531"
            visible: false
            height: 4
            width: m.top.width
            translation: [0, m.top.height - 4]
        })
        m.label.color = "#000000"
        if m.rowContent <> invalid then m.rowContent.observeField("active", "setActive")
        m.top.active = (m.rowContent.active = buttonID)
    else
        m.background.setFields({
            color: "#000000"
            visible: true
            height: m.top.height
            width: m.top.width
            translation: [0, 0]
        })
        m.label.color = "#ffffff"
        if m.rowContent <> invalid then m.rowContent.unobserveField("active")
    end if

end sub

sub onSize(ev)

    value = ev.getData()
    field = ev.getField()

    m.label[field] = value

    ' in case the buttons width or height values are changed after the content is set, reajust the buttons background size and position
    if m.top.itemContent <> invalid then
        isTab = (m.top.rowIndex = 0)
        if isTab then
            m.background.setFields({
                width: m.top.width
                translation: [0, m.top.height - 4]
            })
        else
            m.background.setFields({
                height: m.top.height
                width: m.top.width
            })
        end if
    end if

end sub

sub setActive(ev)
    m.top.active = (ev.getData() = m.top.itemContent.id)
end sub

sub onActive(ev)
    active = ev.getData()
    m.background.visible = active
end sub