ProjectFramework = ProjectFramework or {}
ProjectFramework.PreConfig = {}

function ProjectFramework.PreConfig.onChatWindowInit()
    ISChat.instance:setVisible(false)
end
Events.OnChatWindowInit.Add(ProjectFramework.PreConfig.onChatWindowInit)