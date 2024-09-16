this.mod_scaling_character_effect <- ::inherit("scripts/skills/skill", {
	m = {
		StolenAttributes = {},
		StolenPerks = []
	},
	function create()
	{
		this.m.ID = "effects.mod_scaling_character";
		this.m.Name = "Scaling Character";
		this.m.Description = "Whenever this character kills a target, he gains +1 to a random base attribute that the target had higher than him, and steals a random perk that he did not yet have.";
		this.m.Icon = "skills/status_effect_73.png";		
		this.m.Type = ::Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
		this.m.IsSerialized = true;

		foreach (key, attribute in ::Const.Attributes)
		{
			if (key != "COUNT")
				this.m.StolenAttributes[attribute] <- 0;
		}
	}

	function getTooltip()
	{
		local ret = this.skill.getTooltip();

		local str = "<div class='msc_attributePredictionHeader'></div>";
		str += "<div class='msc_attributePredictionContainer'>";
		str += format("<span class='msc_attributePredictionItem'><img src='coui://%s'/> <span class='msc_attributePredictionSingle'>%i</span></span>", "gfx/ui/icons/health.png", this.m.StolenAttributes[::Const.Attributes.Hitpoints]);
		str += format("<span class='msc_attributePredictionItem'><img src='coui://%s'/> <span class='msc_attributePredictionSingle'>%i</span></span>", "gfx/ui/icons/melee_skill.png", this.m.StolenAttributes[::Const.Attributes.MeleeSkill]);
		str += format("<span class='msc_attributePredictionItem'><img src='coui://%s'/> <span class='msc_attributePredictionSingle'>%i</span></span>", "gfx/ui/icons/fatigue.png", this.m.StolenAttributes[::Const.Attributes.Fatigue]);
		str += format("<span class='msc_attributePredictionItem'><img src='coui://%s'/> <span class='msc_attributePredictionSingle'>%i</span></span>", "gfx/ui/icons/ranged_skill.png", this.m.StolenAttributes[::Const.Attributes.RangedSkill]);
		str += format("<span class='msc_attributePredictionItem'><img src='coui://%s'/> <span class='msc_attributePredictionSingle'>%i</span></span>", "gfx/ui/icons/bravery.png", this.m.StolenAttributes[::Const.Attributes.Bravery]);
		str += format("<span class='msc_attributePredictionItem'><img src='coui://%s'/> <span class='msc_attributePredictionSingle'>%i</span></span>", "gfx/ui/icons/melee_defense.png", this.m.StolenAttributes[::Const.Attributes.MeleeDefense]);
		str += format("<span class='msc_attributePredictionItem'><img src='coui://%s'/> <span class='msc_attributePredictionSingle'>%i</span></span>", "gfx/ui/icons/initiative.png", this.m.StolenAttributes[::Const.Attributes.Initiative]);
		str += format("<span class='msc_attributePredictionItem'><img src='coui://%s'/> <span class='msc_attributePredictionSingle'>%i</span></span>", "gfx/ui/icons/ranged_defense.png", this.m.StolenAttributes[::Const.Attributes.RangedDefense]);
		str += "</div>";

		ret.push({
			id = 3,
			type = "description",
			rawHTMLInText = true,
			text = str
		});

		if (this.m.StolenPerks.len() != 0)
		{
			local perksText = "";
			foreach (id in this.m.StolenPerks)
			{
				local perkDef = ::Const.Perks.findById(id);				
				local fileName = split(perkDef.Script, "/").top();
				perksText += ::ScalingCharacter.Mod.Tooltips.parseString(format("[Img/gfx/%s|%s]", perkDef.Icon, "Perk+" + fileName))
			}
			ret.push({
				id = 10,
				type = "text",
				text = perksText			
			});
		}

		return ret;
	}

	function onTargetKilled( _targetEntity, _skill )
	{
		local actor = this.getContainer().getActor();

		local potential = [];
		foreach (skill in _targetEntity.getSkills().m.Skills)
		{
			if (skill.isType(::Const.SkillType.Perk) && !this.getContainer().hasSkill(skill.getID()))
				potential.push(skill);
		}

		if (potential.len() != 0)
		{
			local perkDef = ::Const.Perks.findById(::MSU.Array.rand(potential).getID());
			this.m.StolenPerks.push(perkDef.ID);
			local perk = ::new(perkDef.Script);
			perk.m.IsRefundable = false;
			this.getContainer().add(perk);
			::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(actor) + " learned " + ::MSU.Text.colorGreen(perkDef.Name) + " from killing " + ::Const.UI.getColorizedEntityName(_targetEntity));
			actor.getPerkTree().addPerk(perkDef.ID, ::Math.rand(1, 7));
		}

		local potentialAttributes = [];
		local targetProperties = _targetEntity.getBaseProperties();
		local myProperties = actor.getBaseProperties();

		if (targetProperties.Hitpoints * targetProperties.HitpointsMult > myProperties.Hitpoints * myProperties.HitpointsMult) potentialAttributes.push(::Const.Attributes.Hitpoints);
		if (targetProperties.getBravery() > myProperties.getBravery()) potentialAttributes.push(::Const.Attributes.Bravery);
		if (targetProperties.Stamina * targetProperties.StaminaMult > myProperties.Stamina * myProperties.StaminaMult) potentialAttributes.push(::Const.Attributes.Fatigue);
		if (targetProperties.Initiative * targetProperties.InitiativeMult > myProperties.Initiative * myProperties.InitiativeMult) potentialAttributes.push(::Const.Attributes.Initiative);		
		if (targetProperties.getMeleeSkill() > myProperties.getMeleeSkill()) potentialAttributes.push(::Const.Attributes.MeleeSkill);
		if (targetProperties.getMeleeDefense() > myProperties.getMeleeDefense()) potentialAttributes.push(::Const.Attributes.MeleeDefense);
		if (targetProperties.getRangedSkill() > myProperties.getRangedSkill()) potentialAttributes.push(::Const.Attributes.RangedSkill);
		if (targetProperties.getRangedDefense() > myProperties.getRangedDefense()) potentialAttributes.push(::Const.Attributes.RangedDefense);

		if (potentialAttributes.len() != 0)
		{
			local attribute = ::MSU.Array.rand(potentialAttributes);			

			this.m.StolenAttributes[attribute] += 1;

			foreach (key, _ in ::Const.Attributes)
			{
				if (key == attribute)
				{
					myProperties[key == "Fatigue" ? "Stamina" : key] += 1;
					break;					
				}
			}

			local attributeName = "";
			switch (attribute)
			{
				case ::Const.Attributes.Hitpoints: attributeName = "Hitpoints"; break;
				case ::Const.Attributes.Bravery: attributeName = "Resolve"; break;
				case ::Const.Attributes.Fatigue: attributeName = "Fatigue"; break;
				case ::Const.Attributes.Initiative: attributeName = "Initiative"; break;
				case ::Const.Attributes.MeleeSkill: attributeName = "Melee Skill"; break;
				case ::Const.Attributes.MeleeDefense: attributeName = "Melee Defense"; break;
				case ::Const.Attributes.RangedSkill: attributeName = "Ranged Skill"; break;
				case ::Const.Attributes.RangedDefense: attributeName = "Ranged Defense"; break;
			}			

			::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(actor) + " gained " + ::MSU.Text.colorGreen("+1 ") + attributeName + " from killing " + ::Const.UI.getColorizedEntityName(_targetEntity));
		}
	}

	function onSerialize( _out )
	{
		this.skill.onSerialize(_out);
		_out.writeU8(this.m.StolenAttributes.len());
		foreach (attribute, amount in this.m.StolenAttributes)
		{
			_out.writeU8(attribute);
			_out.writeU16(amount);
		}

		_out.writeU16(this.m.StolenPerks.len());
		foreach (id in this.m.StolenPerks)
		{
			_out.writeString(id);
		}	
	}

	function onDeserialize( _in )
	{
		this.skill.onDeserialize(_in);
		this.m.StolenAttributes = {};
		local len = _in.readU8();		
		for (local i = 0; i < len; i++)
		{
			local key = _in.readU8();
			local value = _in.readU16();
			this.m.StolenAttributes[key] <- value;
		}

		this.m.StolenPerks = [];
		len = _in.readU16();
		for (local i = 0; i < len; i++)
		{
			this.m.StolenPerks.push(_in.readString());
		}
	}
});
