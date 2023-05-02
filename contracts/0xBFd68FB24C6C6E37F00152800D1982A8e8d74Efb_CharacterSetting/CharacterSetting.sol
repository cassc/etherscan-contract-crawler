/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

// SPDX-License-Identifier: UNLICENSED

/********************************
**:::::::::::::::::::::::::::::**
**:::::██████████████::::::::::**
**:::██::::::::::::::██::::::::**
**:::██████████████████████::::**
**:::::::::::::::::::::::::::::**
**:::████::████:███:█::████::::**
**:::██:██:███:::██:█::████::::**
**:::████::████::::██::████::::**
**:::::::::::::::::::::::::::::**
********************************/

/// Title    : Character Setting
/// Author   : 0xSumo of @TheCapLabs
/// Twitter  : https://twitter.com/TheCapLabs
/// Feauture : Database for changing Name, Bio and Character for your NFT

pragma solidity ^0.8.0;

/// OwnControl by 0xSumo
abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminSet(bytes32 indexed controllerType, bytes32 indexed controllerSlot, address indexed controller, bool status);
    address public owner;
    mapping(bytes32 => mapping(address => bool)) internal admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(owner == msg.sender, "only owner");_; }
    modifier onlyAdmin(string memory type_) { require(isAdmin(type_, msg.sender), "only admin");_; }
    function transferOwnership(address newOwner) external onlyOwner { emit OwnershipTransferred(owner, newOwner); owner = newOwner; }
    function setAdmin(string calldata type_, address controller, bool status) external onlyOwner { bytes32 typeHash = keccak256(abi.encodePacked(type_)); admin[typeHash][controller] = status; emit AdminSet(typeHash, typeHash, controller, status); }
    function isAdmin(string memory type_, address controller) public view returns (bool) { bytes32 typeHash = keccak256(abi.encodePacked(type_)); return admin[typeHash][controller]; }
}

contract CharacterSetting is OwnControll {

    struct NamesAndBiosAndChara { 
        string names;
        string bios;
        uint16[6] traits;
    }
    
    event NameChanged(uint16 tokenId_, string name_);
    event BioChanged(uint16 tokenId_, string bio_);
    event TraitChanged(uint16 tokenId_, uint8 traitNumber_, uint16 traitValue_);

    mapping(uint16 => string) public Name;
    mapping(uint16 => string) public Bio;
    mapping(uint16 => mapping(uint8 => uint16)) public traits;

    function adminChangeName(uint16 tokenId_, string calldata name_) external onlyAdmin("NAME") {
        Name[tokenId_] = name_; 
        emit NameChanged(tokenId_, name_);
    }
    
    function adminChangeBio(uint16 tokenId_, string calldata bio_) external onlyAdmin("BIO") {
        Bio[tokenId_] = bio_;
        emit BioChanged(tokenId_, bio_);
    }

    function adminChangeTrait(uint16 tokenId_, uint8 traitNumber_, uint16 traitValue_) external onlyAdmin("TRAIT") {
        require(traitNumber_ >= 1 && traitNumber_ <= 6, "Invalid trait number");
        traits[tokenId_][traitNumber_] = traitValue_;
        emit TraitChanged(tokenId_, traitNumber_, traitValue_);
    }

    function getAllNamesAndBiosAndChara() external view returns (NamesAndBiosAndChara[1000] memory) {
        NamesAndBiosAndChara[1000] memory _NamesAndBiosAndChara; /// Array of 1000 (0 to 999)
        for (uint16 i; i < 1000;) {
            string memory _name  = Name[i];
            string memory _bio   = Bio[i];
            uint16[6] memory _traits;
            for (uint8 j = 1; j <= 6; j++) { /// Number of trait
                _traits[j - 1] = traits[i][j];
            }
            _NamesAndBiosAndChara[i] = NamesAndBiosAndChara(_name, _bio, _traits);
            unchecked { ++i; }
        }
        return _NamesAndBiosAndChara;
    }
}