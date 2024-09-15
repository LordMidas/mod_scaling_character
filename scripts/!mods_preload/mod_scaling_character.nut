::ScalingCharacter <- {
	ID = "mod_scaling_character",
	Name = "Scaling Character",
	Version = "1.0.0",

	function add( _broName )
	{
		::getBro(_broName).getSkills().add(::new("scripts/skills/effects/mod_scaling_character_effect"));
	}

	function remove( _broName )
	{
		::getBro(_broName).getSkills().removeByID("effects.mod_scaling_character");
	}
}

local mod = ::Hooks.register(::ScalingCharacter.ID, ::ScalingCharacter.Version, ::ScalingCharacter.Name);
mod.require([
	"mod_msu",
	"mod_reforged",
	"mod_dynamic_perks"
]);

mod.queue(">mod_msu", function() {
	::ScalingCharacter.Mod <- ::MSU.Class.Mod(::ScalingCharacter.ID, ::ScalingCharacter.Version, ::ScalingCharacter.Name);
	::ScalingCharacter.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.GitHub, "https://github.com/LordMidas/mod_scaling_character");
	::ScalingCharacter.Mod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.GitHub);

	::Hooks.registerCSS("ui/mods/mod_scaling_character/generic.css");
});
