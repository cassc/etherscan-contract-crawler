// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Regular Names v1.0 
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Names is AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    IERC721 regularsNFT =       IERC721(0x6d0de90CDc47047982238fcF69944555D27Ecb25); // Regular NFT Address
	mapping(uint => string)     public      names;       // Regular name by Regular Id 
    mapping(string => bool)     private     reserved;    // Names can only be used once
	mapping(uint => bool)       private     locked;      // Admin can lock names (in case of abuse)
    uint public constant MAX_CHARS = 28;
    uint public constant MAX_SPACES = 2;
    bool public RENAMING_OPEN = false;

	event NameChange (uint256 indexed tokenId, string newName, address sender);

	constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(ADMIN_ROLE, msg.sender);
	}

// Public function for free renaming

    function freeRename(uint _tokenId, string memory _name) public { 
        _name = toLower(_name);
        require(RENAMING_OPEN, "Free rename not available");
        _setName(_tokenId, _name);
    }

// View

    function isOwnerOfReg(uint _tokenId, address _addr) public view returns (bool) {
        return regularsNFT.ownerOf(_tokenId) == _addr;
    }

    function hasName(uint _tokenId) public view returns (bool) {
        return reserved[names[_tokenId]];
    }

    function isReserved(string memory _name) public view returns (bool) {
        return reserved[toLower(_name)];
    }

    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 5) return false; // Must be longer than 4
        if(b.length > MAX_CHARS) return false; // Cannot be longer than MAX_CHARS
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];
        uint numSpaces = 0;

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];
            if (char == 0x20)
                numSpaces++;
            if (numSpaces > MAX_SPACES) return false; // Must have fewer than max_spaces
            if (
                (i == b.length - 1) && // Must contain one space
                (numSpaces == 0) && 
                (char != 0x20)
            ) 
                return false;
            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces
            if(
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
                // !(char == 0x2E) //period
            )
                return false;
            lastChar = char;
        }
        return true;
    }

// Admin

    function rename(uint _tokenId, string memory _name) public onlyRole(ADMIN_ROLE) {
        _setName(_tokenId, _name);
    }

    function overrideName(uint _tokenId, string memory _name) public onlyRole(ADMIN_ROLE) {
        _name = toLower(_name);
        reserved[names[_tokenId]] = false; // un-reserve the old name
        reserved[_name] = true;
        names[_tokenId] = _name;
        emit NameChange(_tokenId, _name, msg.sender);
    }

    function lockName(uint _tokenId, bool _locked) public onlyRole(ADMIN_ROLE) {
        locked[_tokenId] = _locked;
    }

    function setRenamingOpen(bool _isOpen) public onlyRole(ADMIN_ROLE) {
        RENAMING_OPEN = _isOpen;
    }

// Internal

    function _setName(uint _tokenId, string memory _name) internal {
        _name = toLower(_name);
        require(regularsNFT.ownerOf(_tokenId) == msg.sender, "Not the owner of Regular");
        require(validateName(_name),"Name not valid");
        require(!reserved[_name],   "Name taken");
        require(!locked[_tokenId],  "Name locked");
        reserved[names[_tokenId]] = false; // un-reserve the old name
        reserved[_name] = true;
        names[_tokenId] = _name;
        emit NameChange(_tokenId, _name, msg.sender);
    }

    function toggleReserveName(string memory str, bool isReserve) internal {
        reserved[toLower(str)] = isReserve;
    }

    function toLower(string memory str) internal pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

}