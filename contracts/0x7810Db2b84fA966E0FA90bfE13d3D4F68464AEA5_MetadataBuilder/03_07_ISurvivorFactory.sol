pragma solidity ^0.8.0;

interface ISurvivorFactory {
    enum SurvivorTrait { Shoes, Pants, Body, Beard, Hair, Head, Shirt, ChestArmor, ShoulderArmor, LegArmor, RightWeapon, LeftWeapon }

    function survivorChestArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorShoulderArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorLegArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorRightWeaponTraitCount(uint8 level) external view returns (uint8);
    function survivorLeftWeaponTraitCount(uint8 level) external view returns (uint8);
    function survivorShoesTraitCount() external view returns (uint8);
    function survivorPantsTraitCount() external view returns (uint8);
    function survivorBodyTraitCount() external view returns (uint8);
    function survivorBeardTraitCount() external view returns (uint8);
    function survivorHairTraitCount() external view returns (uint8);
    function survivorHeadTraitCount() external view returns (uint8);
    function survivorShirtTraitCount() external view returns (uint8);
    function survivorSVG(uint8 level, uint8[] memory traits) external view returns (bytes memory);
    function survivorTrait(SurvivorTrait trait, uint8 level, uint8 traitNumber) external view returns (string memory);
}