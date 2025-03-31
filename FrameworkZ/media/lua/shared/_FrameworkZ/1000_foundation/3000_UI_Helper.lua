FrameworkZ = FrameworkZ or {}
FrameworkZ.UI = {}

--! \brief Get the x position to center text based on the text's width and what you're centering relative to.
--! \param \int length The length of the object you're centering the text in.
--! \param \string fontSize The font size of the text (could be UIFont.Small, UIFont.Medium, UIFont.Large, or UIFont.Title).
--! \param \string text The text you're centering.
function FrameworkZ.UI.GetCenteredX(length, fontSize, text)
    local width = getTextManager():MeasureStringX(fontSize, text)

    return (length / 2) - (width / 2)
end

function FrameworkZ.UI.GetMiddle(length, fontSize, text)
    local width = getTextManager():MeasureStringX(fontSize, text)

    return (length - width) / 2
end

function FrameworkZ.UI.GetHeight(fontSize, text)
    local height = getTextManager():MeasureStringY(fontSize, text)

    return height
end
