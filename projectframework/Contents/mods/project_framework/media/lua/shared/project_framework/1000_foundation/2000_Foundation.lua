--! \mainpage Main Page
--! Created By RJ_RayJay
--! \section Introduction
--! Project HL2RP is a roleplay framework for the game Project Zomboid. This framework is designed to be a base for roleplay servers, providing a variety of features and systems to help server owners create a unique and enjoyable roleplay experience for their players. We have plans to make a standalone framework for Project Zomboid, but for now, we are focusing on the Project HL2RP framework integrated with the HL2RP gamemode.
--! \section Features
--! The Project HL2RP framework includes a variety of features and systems to help server owners create a unique and enjoyable roleplay experience for their players. Some of the features and systems include:
--! - Characters
--! - Factions
--! - Entities
--! - Items
--! - Inventories
--! - Trading
--! - Crafting
--! - Skills
--! - Vehicles
--! - Housing
--! - Jobs
--! - Quests
--! - Events
--! - Admin
--! - ...and more!
--! \section Installation
--! To install the Project HL2RP framework, simply download the latest release from the Steam Workshop and add the Workshop ID/Mod ID into your Project Zomboid server's config file. After installing, you can start your server and the framework will be ready to use.
--! \section Usage
--! The Project HL2RP framework is designed to be easy to use and extend. The framework is built using Lua, a lightweight, multi-paradigm programming language designed primarily for embedded use in applications. The framework is designed to be modular, allowing server owners to easily add, remove, and modify features and systems to suit their needs. The framework also includes extensive documentation to help server owners understand how to use and extend the framework.
--! \section Contributing
--! The Project HL2RP framework is an open-source project and we welcome contributions from the community. If you would like to contribute to the framework, you can do so by forking the GitHub repository, making your changes, and submitting a pull request. We also welcome bug reports, feature requests, and feedback from the community. If you have any questions or need help with the framework, you can join the Project HL2RP Discord server and ask for assistance in the #support channel.
--! \section License
--! The Project HL2RP framework is licensed under the MIT License, a permissive open-source license that allows you to use, modify, and distribute the framework for free. You can find the full text of the MIT License in the LICENSE file included with the framework. We chose the MIT License because we believe in the power of open-source software and want to encourage collaboration and innovation in the Project Zomboid community.
--! \section Support
--! If you need help with the Project HL2RP framework, you can join the Project HL2RP Discord server and ask for assistance in the #support channel. We have a friendly and knowledgeable community that is always willing to help with any questions or issues you may have. We also have a variety of resources available to help you get started with the framework, including documentation, tutorials, and example code.
--! \section Conclusion
--! The Project HL2RP framework is a powerful and flexible tool for creating roleplay servers in Project Zomboid. Whether you are a server owner looking to create a unique roleplay experience for your players or a developer looking to contribute to an open-source project, the Project HL2RP framework has something for everyone. We hope you enjoy using the framework and look forward to seeing the amazing roleplay experiences you create with it.
--! \section Links
--! - GitHub Repository: Coming Soon(tm)
--! - Discord Server: https://discord.gg/dEZwKHPeWZ
--! - Documentation: https://projectframework-docs.pixelport.community
--! - Tutorials: Coming Soon(tm)
--! - Example Code: Coming Soon(tm)


--! \page globalVars Global Variables
--! \section ProjectFramework ProjectFramework
--! ProjectFramework
--! The global table that contains all of the framework.
--! [table]: /var_types.html#table "table"
--! \page varTypes Variable Types
--! \section string string
--! A string is a sequence of characters. Strings are used to represent text and are enclosed in double quotes or single quotes.
--! \section boolean boolean
--! A boolean is a value that can be either true or false. Booleans are used to represent logical values.
--! \section integer integer
--! A integer is a numerical value without any decimal points.
--! \section float float
--! A float is a numerical value with decimal points.
--! \section table table
--! A table is a collection of key-value pairs. It is the only data structure available in Lua that allows you to store data with arbitrary keys and values. Tables are used to represent arrays, sets, records, and other data structures.
--! \section function function
--! A function is a block of code that can be called and executed. Functions are used to encapsulate and reuse code.
--! \section nil nil
--! Nil is a special value that represents the absence of a value. Nil is used to indicate that a variable has no value.
--! \section any any
--! Any is a placeholder that represents any type of value. It is used to indicate that a variable can hold any type of value.
--! \section mixed mixed
--! Mixed is a placeholder that represents a combination of different types of values. It is used to indicate that a variable can hold a variety of different types of values.
--! \section class class
--! Class is a placeholder that represents a class of objects by a table set to a metatable.

--! \brief ProjectFramework global table.
--! \class ProjectFramework
ProjectFramework = ProjectFramework or {}

--! \brief Foundation for ProjectFramework.
--! \class Foundation
--! \memberof ProjectFramework
ProjectFramework.Foundation = {}
ProjectFramework.Foundation.__index = ProjectFramework.Foundation

--! \brief Modules for ProjectFramework.
--! \memberof ProjectFramework
ProjectFramework.Modules = {}

--! \brief Create a new instance of the ProjectFramework Framework.
--! \return \table The new instance of the ProjectFramework Framework.
function ProjectFramework.Foundation.New()
    local object = {
        version = "0.0.0"
    }

    setmetatable(object, ProjectFramework.Foundation)

	return object
end

--! \brief Create a new module for the ProjectFramework Framework.
--! \param MODULE_TABLE \table The table to use as the module.
--! \param moduleName \string The name of the module.
--! \return \table The new module.
function ProjectFramework.Foundation:NewModule(MODULE_TABLE, moduleName)
	if (not ProjectFramework.Modules[moduleName]) then
        local object = {};
		setmetatable(object, MODULE_TABLE)
		MODULE_TABLE.__index = MODULE_TABLE
		ProjectFramework.Modules[moduleName] = object
	end;
	
	return ProjectFramework.Modules[moduleName]
end

--! \brief Get the version of the ProjectFramework Framework.
--! \return \string The version of the ProjectFramework Framework.
function ProjectFramework.Foundation:GetVersion()
    return self.version
end

if isClient() then

	function ProjectFramework.Foundation.LoadGridsquare(square)
		for k, v in pairs(ProjectFramework.Modules) do
			if v.LoadGridsquare then
				v.LoadGridsquare(v, square)
			end
		end
	end
	Events.LoadGridsquare.Add(ProjectFramework.Foundation.LoadGridsquare)

	--! \brief Called when the game starts. Executes the OnGameStart function for all modules.
	function ProjectFramework.Foundation.OnGameStart()
		for k, v in pairs(ProjectFramework.Modules) do
			if v.OnGameStart then
				v.OnGameStart(v)
			end
		end
	end
	Events.OnGameStart.Add(ProjectFramework.Foundation.OnGameStart)

	--! \brief Called when the player disconnects. Executes the OnDisconnect function for all modules.
	function ProjectFramework.Foundation.OnDisconnect()
		for k, v in pairs(ProjectFramework.Modules) do
			if v.OnDisconnect then
				v.OnDisconnect(v)
			end
		end
	end
	Events.OnDisconnect.Add(ProjectFramework.Foundation.OnDisconnect)
	
end

if not isClient() then

	--! \brief Called when the server starts. Executes the OnServerStarted function for all modules.
	function ProjectFramework.Foundation.OnServerStarted()
		for k, v in pairs(ProjectFramework.Modules) do
			if v.OnServerStarted then
				v.OnServerStarted(v)
			end
		end
	end
	Events.OnServerStarted.Add(ProjectFramework.Foundation.OnServerStarted)
end

ProjectFramework.Foundation.New()
