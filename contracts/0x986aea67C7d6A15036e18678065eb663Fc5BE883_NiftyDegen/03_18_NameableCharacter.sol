// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NiftyLeagueCharacter.sol";

interface INFTL is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

/**
 * @title NameableCharacter (Extendable to allow name changes on NFTs)
 * @dev Extends NiftyLeagueCharacter (ERC721)
 */
abstract contract NameableCharacter is NiftyLeagueCharacter {
    /// @notice Cost to change character name in NFTL
    uint256 public constant NAME_CHANGE_PRICE = 1000e18; // 1000 NFTL

    /// @dev Mapping if name string is already used
    mapping(string => bool) private _nameReserved;

    event NameUpdated(uint256 indexed tokenId, string previousName, string newName);

    // External functions

    /**
     * @notice Retrieve name of token
     * @param tokenId ID of NFT
     * @return NFT name
     */
    function getName(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        return _characters[tokenId].name;
    }

    /**
     * @notice Change name of NFT payable with {NAME_CHANGE_PRICE} NFTL
     * @param tokenId ID of NFT
     * @param newName New name to validate and set on NFT
     * @return New NFT name
     */
    function changeName(uint256 tokenId, string memory newName) external returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        string memory prevName = _characters[tokenId].name;
        require(sha256(bytes(newName)) != sha256(bytes(prevName)), "New name and old name are equal");
        require(validateName(newName), "Name is not allowed");
        require(!isNameReserved(newName), "Name already reserved");

        INFTL(_nftlAddress).burnFrom(_msgSender(), NAME_CHANGE_PRICE);
        if (bytes(_characters[tokenId].name).length > 0) {
            _toggleReserveName(_characters[tokenId].name, false);
        }
        _toggleReserveName(newName, true);
        _characters[tokenId].name = newName;
        emit NameUpdated(tokenId, prevName, newName);
        return newName;
    }

    // Public functions

    /**
     * @notice Check if name is already reserved
     * @param nameString Name to validate
     * @return True if name is unique
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[_toLower(nameString)];
    }

    /**
     * @notice Check for valid name string (Alphanumeric and spaces without leading or trailing space)
     * @param newName Name to validate
     * @return True if name input is valid
     */
    function validateName(string memory newName) public pure returns (bool) {
        bytes memory byteName = bytes(newName);
        if (byteName.length < 1 || byteName.length > 32) return false; // name cannot be longer than 32 characters
        if (byteName[0] == 0x20 || byteName[byteName.length - 1] == 0x20) return false; // reject leading and trailing space

        bytes1 lastChar = byteName[0];
        for (uint256 i; i < byteName.length; i++) {
            bytes1 currentChar = byteName[i];
            if (currentChar == 0x20 && lastChar == 0x20) return false; // reject double spaces
            if (
                !(currentChar >= 0x30 && currentChar <= 0x39) && //0-9
                !(currentChar >= 0x41 && currentChar <= 0x5A) && //A-Z
                !(currentChar >= 0x61 && currentChar <= 0x7A) && //a-z
                !(currentChar == 0x20) //space
            ) return false;
            lastChar = currentChar;
        }
        return true;
    }

    // Private functions

    /**
     * @notice Reserves the name if isReserve is set to true, de-reserves if set to false
     * @param str NFT name string
     * @param isReserved Bool if name should be reserved or not
     */
    function _toggleReserveName(string memory str, bool isReserved) private {
        _nameReserved[_toLower(str)] = isReserved;
    }

    /**
     * @notice Converts strings to lowercase
     * @param str Any string
     * @return String to lower case
     */
    function _toLower(string memory str) private pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}