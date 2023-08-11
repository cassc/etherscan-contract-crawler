/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    constructor() { 
        owner = msg.sender; 
    }
    
    modifier onlyOwner { 
        require(owner == msg.sender, "onlyOwner not owner!");
        _; 
    }
    
    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}

abstract contract Controllerable is Ownable {

    event ControllerSet(string indexed controllerType, bytes32 indexed controllerSlot, 
        address indexed controller, bool status);

    mapping(bytes32 => mapping(address => bool)) internal __controllers;

    function isController(string memory type_, address controller_) public 
    view returns (bool) {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        return __controllers[_slot][controller_];
    }

    modifier onlyController(string memory type_) {
        require(isController(type_, msg.sender), "Controllerable: Not Controller!");
        _;
    }

    function setController(string memory type_, address controller_, bool bool_) 
    public onlyOwner {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        __controllers[_slot][controller_] = bool_;
        emit ControllerSet(type_, _slot, controller_, bool_);
    }
}

interface iCS {
    // Structs of Characters
    struct Character {
        uint8 race_;
        uint8 renderType_;
        uint16 transponderId_;
        uint16 spaceCapsuleId_;
        uint8 augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }
    struct Stats {
        uint8 strength_; 
        uint8 agility_; 
        uint8 constitution_; 
        uint8 intelligence_; 
        uint8 spirit_; 
    }
    struct Equipment {
        uint8 weaponUpgrades_;
        uint8 chestUpgrades_;
        uint8 headUpgrades_;
        uint8 legsUpgrades_;
        uint8 vehicleUpgrades_;
        uint8 armsUpgrades_;
        uint8 artifactUpgrades_;
        uint8 ringUpgrades_;
    }

    // View Functions
    function names(uint256 tokenId_) external view returns (string memory);
    function bios(uint256 tokenId_) external view returns (string memory);
    function characters(uint256 tokenId_) external view returns (Character memory);
    function stats(uint256 tokenId_) external view returns (Stats memory);
    function equipments(uint256 tokenId_) external view returns (Equipment memory);
    function contractToRace(address contractAddress_) external view returns (uint8);
}

interface iMartians {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

interface iMES {
    function transferFrom(address from_, address to_, uint256 amount_) 
    external returns (bool);
}

// The Locally Supplied Interface
interface iMarsRulerRegistry {

    struct GearConfig {
        bool hasConfig;
        uint8 weaponType;
        uint8 chestType;
        uint8 headType;
        uint8 legsType;
        uint8 vehicleType;
        uint8 armsType;
        uint8 artifactType;
        uint8 ringType;
    }

    function characterToGearconfig(uint256 tokenId_) external view
    returns (GearConfig memory);
}

contract MarsRulerRegistry is Controllerable {

    ///// Interfaces ///// 
    // NOTE: MARTIANS ADDRESS MUST BE CHANGED TO V3!!! THIS IS V2!
    iMartians public Martians = iMartians(0x53beA59B69bF9e58E0AFeEB4f34f49Fc29D10F55); 
    iCS public CS = iCS(0xC7C40032E952F52F1ce7472913CDd8EeC89521c4);
    iMES public MES = iMES(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);

    struct GearConfig {
        bool hasConfig; // Set to True on write, False on reset
        uint8 weaponType;
        uint8 chestType;
        uint8 headType;
        uint8 legsType;
        uint8 vehicleType;
        uint8 armsType;
        uint8 artifactType;
        uint8 ringType;
    }

    event GearChange(address indexed owner, uint256 indexed tokenId, GearConfig config);
    event GearReset(address indexed owner, uint256 indexed tokenId);

    mapping(uint256 => GearConfig) public characterToGearConfig;

    uint256 public GEAR_CHANGE_COST = 1000 ether; // Not Immutable!

    ///// Administrative Functions /////
    function O_setContracts(address martians_, address cs_, address mes_) 
    external onlyOwner {
        if (martians_ != address(0)) Martians = iMartians(martians_);
        if (cs_ != address(0)) CS = iCS(cs_);
        if (mes_ != address(0)) MES = iMES(mes_);
    }
    function O_setGearChangeCost(uint256 cost_) external onlyOwner {
        GEAR_CHANGE_COST = cost_;
    }

    ///// Controller Functions /////
    function C_setCharacterGear(uint256 tokenId_, GearConfig memory gearConfig_) 
    external onlyController("SETTER") {
        gearConfig_.hasConfig = true;
        characterToGearConfig[tokenId_] = gearConfig_;
        emit GearChange(msg.sender, tokenId_, gearConfig_);
    }
    function C_resetCharacterGear(uint256 tokenId_) external onlyController("SETTER") {
        delete characterToGearConfig[tokenId_];
        emit GearReset(msg.sender, tokenId_);
    }

    ///// Usage Functions /////
    function setGear(uint256 tokenId_, GearConfig memory gearConfig_) external {
        // Validate Ownership
        require(msg.sender == Martians.ownerOf(tokenId_),
                "You are not the owner!");

        // Validate Augments
        require(10 == CS.characters(tokenId_).augments_,
                "Your Martian is not a Ruler yet!");
            
        // Consume $MES
        bool _success = MES.transferFrom(msg.sender, address(this), GEAR_CHANGE_COST);
        require(_success, "$MES deduction failed!");

        // Set Gear Config
        gearConfig_.hasConfig = true; // Force a True value on gearConfig
        characterToGearConfig[tokenId_] = gearConfig_; // Set the gearConfig

        // Emit GearChange Event
        emit GearChange(msg.sender, tokenId_, gearConfig_);
    }

    function resetGear(uint256 tokenId_) external {
        // Validate Ownership
        require(msg.sender == Martians.ownerOf(tokenId_),
                "You are not the owner!");
        
        // Validate Gear Config Exists
        require(characterToGearConfig[tokenId_].hasConfig,
                "Ruler has no config!");
        
        // Delete the Config. This forces the hasConfig bool to False
        delete characterToGearConfig[tokenId_];

        // Emit GearReset Event
        emit GearReset(msg.sender, tokenId_);
    }
}