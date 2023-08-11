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

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

interface IERC20 {
    function transferFrom(address from_, address to_, uint256 amount_) 
    external returns (bool);
}

// This simple contract simply lets you take the helmet of your character
// Off or on
contract CharacterRegsitry is Controllerable {

    // NOTE: MARTIANS ADDRESS MUST BE CHANGED TO V3!!! THIS IS V2!
    IERC721 public Martians = IERC721(0x53beA59B69bF9e58E0AFeEB4f34f49Fc29D10F55); 
    IERC20 public MES = IERC20(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);

    event HelmetOff(address indexed owner, uint256 indexed tokenId);
    event HelmetOn(address indexed owner, uint256 indexed tokenId);
    
    // Helmets are on by default
    mapping(uint256 => bool) public characterToHelmetOff;

    uint256 public HELMET_CHANGE_COST = 50 ether; // Not Immutable!

    ///// Administrative Functions /////
    function O_setContracts(address martians_, address mes_) external onlyOwner {
        if (martians_ != address(0)) Martians = IERC721(martians_);
        if (mes_ != address(0)) MES = IERC20(mes_);
    }
    function O_setHelmetChangeCost(uint256 cost_) external onlyOwner {
        HELMET_CHANGE_COST = cost_;
    }

    ///// Controller Functions /////
    function C_takeHelmetsOff(uint256[] calldata tokenIds_) external 
    onlyController("SETTER") {
        uint256 l;
        for (uint256 i = 0; i < l;) {
            require(!characterToHelmetOff[tokenIds_[i]],
                    "Character already has helmet off");
            characterToHelmetOff[tokenIds_[i]] = true;
            emit HelmetOff(msg.sender, tokenIds_[i]);
            unchecked { ++i; }
        }
    }
    function C_putHelmetsOn(uint256[] calldata tokenIds_) external 
    onlyController("SETTER") {
        uint256 l;
        for (uint256 i = 0; i < l;) {
            require(characterToHelmetOff[tokenIds_[i]],
                    "Character already has helmet on");
            delete characterToHelmetOff[tokenIds_[i]];
            emit HelmetOn(msg.sender, tokenIds_[i]);
            unchecked { ++i; }
        }
    }

    // Take off the helmet
    function takeOffHelmet(uint256 tokenId_) external {
        // Validate Ownership
        require(msg.sender == Martians.ownerOf(tokenId_),
                "You are not the owner!");

        // Validate Helmet Status
        require(!characterToHelmetOff[tokenId_], 
                "Character already has helmet off");
        
        // Consume $MES
        bool _success = MES.transferFrom(msg.sender, address(this), HELMET_CHANGE_COST);
        require(_success, "$MES deduction failed!");

        // Set the Helmet Config
        characterToHelmetOff[tokenId_] = true;

        // Emit HelmetOff event
        emit HelmetOff(msg.sender, tokenId_);
    }

    // Put on the helmet
    function putOnHelmet(uint256 tokenId_) external {
        // Validate Ownership
        require(msg.sender == Martians.ownerOf(tokenId_),
                "You are not the owner!");

        // Validate Helmet Status
        require(characterToHelmetOff[tokenId_],
                "Character already has helmet on");

        // Consume $MES
        bool _success = MES.transferFrom(msg.sender, address(this), HELMET_CHANGE_COST);
        require(_success, "$MES deduction failed!");

        // Set the Helmet Config
        delete characterToHelmetOff[tokenId_];

        // Emit HelmetOff event
        emit HelmetOn(msg.sender, tokenId_);
    }
}