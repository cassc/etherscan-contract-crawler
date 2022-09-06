pragma solidity ^0.8.0;

interface IZombieMetadata {
    enum ZombieTrait { Torso, LeftArm, RightArm, Legs, Head }

    function zombieTorsoTraitCount(uint8 level) external view returns (uint8);
    function zombieLeftArmTraitCount(uint8 level) external view returns (uint8);
    function zombieRightArmTraitCount(uint8 level) external view returns (uint8);
    function zombieLegsTraitCount(uint8 level) external view returns (uint8);
    function zombieHeadTraitCount(uint8 level) external view returns (uint8);
    function zombieSVG(uint8 level, uint8[] memory traits) external view returns (bytes memory);
    function zombieTrait(ZombieTrait trait, uint8 level, uint8 traitNumber) external view returns (string memory);
}