local class = require('class')
local Sound = require('sound')
local UI    = require('ui')

local colors = _G.colors

UI.Form = class(UI.Window)
UI.Form.defaults = {
	UIElement = 'Form',
	values = { },
	margin = 2,
	event = 'form_complete',
	cancelEvent = 'form_cancel',
}
function UI.Form:postInit()
	self:createForm()
end

function UI.Form:reset()
	for _,child in pairs(self.children) do
		if child.reset then
			child:reset()
		end
	end
end

function UI.Form:setValues(values)
	self:reset()
	self.values = values
	for _,child in pairs(self.children) do
		if child.formKey then
			-- this should be child:setValue(self.values[child.formKey])
			-- so chooser can set default choice if null
			-- null should be valid as well
			child.value = self.values[child.formKey] or ''
		end
	end
end

function UI.Form:createForm()
	self.children = self.children or { }

	if not self.labelWidth then
		self.labelWidth = 1
		for _, child in pairs(self) do
			if type(child) == 'table' and child.UIElement then
				if child.formLabel then
					self.labelWidth = math.max(self.labelWidth, #child.formLabel + 2)
				end
			end
		end
	end

	local y = self.margin
	for _, child in pairs(self) do
		if type(child) == 'table' and child.UIElement then
			if child.formKey then
				child.value = self.values[child.formKey] or ''
			end
			if child.formLabel then
				child.x = self.labelWidth + self.margin - 1
				child.y = y
				if not child.width and not child.ex then
					child.ex = -self.margin
				end

				table.insert(self.children, UI.Text {
					x = self.margin,
					y = y,
					textColor = colors.black,
					width = #child.formLabel,
					value = child.formLabel,
				})
			end
			if child.formKey or child.formLabel then
				y = y + 1
			end
		end
	end

	if not self.manualControls then
		table.insert(self.children, UI.Button {
			y = -self.margin, x = -12 - self.margin,
			text = 'Ok',
			event = 'form_ok',
		})
		table.insert(self.children, UI.Button {
			y = -self.margin, x = -7 - self.margin,
			text = 'Cancel',
			event = self.cancelEvent,
		})
	end
end

function UI.Form:validateField(field)
	if field.required then
		if not field.value or #tostring(field.value) == 0 then
			return false, 'Field is required'
		end
	end
	if field.validate == 'numeric' then
		if #tostring(field.value) > 0 then
			if not tonumber(field.value) then
				return false, 'Invalid number'
			end
		end
	end
	return true
end

function UI.Form:save()
	for _,child in pairs(self.children) do
		if child.formKey then
			local s, m = self:validateField(child)
			if not s then
				self:setFocus(child)
				Sound.play('entity.villager.no', .5)
				self:emit({ type = 'form_invalid', message = m, field = child })
				return false
			end
		end
	end
	for _,child in pairs(self.children) do
		if child.formKey then
			if (child.pruneEmpty and type(child.value) == 'string' and #child.value == 0) or
				 (child.pruneEmpty and type(child.value) == 'boolean' and not child.value) then
				self.values[child.formKey] = nil
			elseif child.validate == 'numeric' then
				self.values[child.formKey] = tonumber(child.value)
			else
				self.values[child.formKey] = child.value
			end
		end
	end

	return true
end

function UI.Form:eventHandler(event)
	if event.type == 'form_ok' then
		if not self:save() then
			return false
		end
		self:emit({ type = self.event, UIElement = self, values = self.values })
	else
		return UI.Window.eventHandler(self, event)
	end
	return true
end
