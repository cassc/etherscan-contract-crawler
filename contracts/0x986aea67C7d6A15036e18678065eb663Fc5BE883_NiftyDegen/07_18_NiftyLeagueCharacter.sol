// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NiftyLeagueCharacter (Base NFT for Nifty League characters)
 * @dev Extends standard ERC721 contract from OpenZeppelin
 */
contract NiftyLeagueCharacter is ERC721, Ownable, Pausable {
    using Strings for string;

    struct Character {
        uint256 traits;
        string name;
    }
    struct CharacterTraits {
        // character
        uint16 tribe;
        uint16 skinColor;
        uint16 furColor;
        uint16 eyeColor;
        uint16 pupilColor;
        //  head
        uint16 hair;
        uint16 mouth;
        uint16 beard;
        //  clothing
        uint16 top;
        uint16 outerwear;
        uint16 print;
        uint16 bottom;
        uint16 footwear;
        uint16 belt;
        //  accessories
        uint16 hat;
        uint16 eyewear;
        uint16 piercing;
        uint16 wrist;
        uint16 hands;
        uint16 neckwear;
        //  items
        uint16 leftItem;
        uint16 rightItem;
    }
    /// @dev Mapping of created character structs from token ID
    mapping(uint256 => Character) internal _characters;

    /// @dev Expected uint if no specific trait is selected
    uint256 internal constant EMPTY_TRAIT = 0;

    /// @dev Mapping if character trait combination exist
    mapping(uint256 => bool) internal _existMap;

    /// @dev Mapping if character trait has been removed
    mapping(uint256 => bool) internal _removedTraitsMap;

    /// @dev Array initialized in order to return removed trait list
    uint16[] internal removedTraits;

    /// @dev Nifty League NFTL token address
    address internal immutable _nftlAddress;

    /**
     * @notice Construct the Nifty League NFTs
     * @param nftlAddress Address of verified Nifty League NFTL contract
     */
    constructor(
        address nftlAddress,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        _nftlAddress = nftlAddress;
    }

    // External functions

    /**
     * @notice Triggers stopped state
     * @dev Requirements: The contract must not be paused
     */
    function pauseMinting() external onlyOwner {
        _pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Requirements: The contract must be paused
     */
    function unpauseMinting() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    /**
     * @notice Retrieve a list of removed character traits
     * @return removedTraits - list of unavailable character traits
     */
    function getRemovedTraits() external view returns (uint16[] memory) {
        return removedTraits;
    }

    /**
     * @notice Retrieve a list of character traits for a token
     * @param tokenId ID of NFT
     * @dev Permissioning not added because it is only callable once.
     * @return _characterTraits - indexed list of character traits
     */
    function getCharacterTraits(uint256 tokenId) external view returns (CharacterTraits memory _characterTraits) {
        require(_exists(tokenId), "nonexistent token");
        Character memory character = _characters[tokenId];
        _characterTraits.tribe = _unpackUint10(character.traits);
        _characterTraits.skinColor = _unpackUint10(character.traits >> 10);
        _characterTraits.furColor = _unpackUint10(character.traits >> 20);
        _characterTraits.eyeColor = _unpackUint10(character.traits >> 30);
        _characterTraits.pupilColor = _unpackUint10(character.traits >> 40);
        _characterTraits.hair = _unpackUint10(character.traits >> 50);
        _characterTraits.mouth = _unpackUint10(character.traits >> 60);
        _characterTraits.beard = _unpackUint10(character.traits >> 70);
        _characterTraits.top = _unpackUint10(character.traits >> 80);
        _characterTraits.outerwear = _unpackUint10(character.traits >> 90);
        _characterTraits.print = _unpackUint10(character.traits >> 100);
        _characterTraits.bottom = _unpackUint10(character.traits >> 110);
        _characterTraits.footwear = _unpackUint10(character.traits >> 120);
        _characterTraits.belt = _unpackUint10(character.traits >> 130);
        _characterTraits.hat = _unpackUint10(character.traits >> 140);
        _characterTraits.eyewear = _unpackUint10(character.traits >> 150);
        _characterTraits.piercing = _unpackUint10(character.traits >> 160);
        _characterTraits.wrist = _unpackUint10(character.traits >> 170);
        _characterTraits.hands = _unpackUint10(character.traits >> 180);
        _characterTraits.neckwear = _unpackUint10(character.traits >> 190);
        _characterTraits.leftItem = _unpackUint10(character.traits >> 200);
        _characterTraits.rightItem = _unpackUint10(character.traits >> 210);
    }

    // Public functions

    /**
     * @notice Check whether trait combo is unique
     * @param traitCombo Generated trait combo packed into uint256
     * @return True if combo is unique and available
     */
    function isUnique(uint256 traitCombo) public view returns (bool) {
        return !_existMap[traitCombo];
    }

    /**
     * @notice Check whether trait is still available
     * @param trait ID of trait
     * @return True if trait has not been removed
     */
    function isAvailableTrait(uint256 trait) public view returns (bool) {
        return !_removedTraitsMap[trait];
    }

    // Internal functions

    /**
     * @notice Unpack trait id from trait list
     * @param traits Section within trait combo
     * @return Trait ID
     */
    function _unpackUint10(uint256 traits) internal pure returns (uint16) {
        return uint16(traits) & 0x03FF;
    }

    /**
     * @notice Generates uint256 bitwise trait combo
     * @param character Indexed list of character traits
     * @param head Indexed list of head traits
     * @param clothing Indexed list of clothing options
     * @param accessories Indexed list of accessories
     * @param items Indexed list of items
     * @dev Each trait is stored in 10 bits
     * @return Trait combo packed into uint256
     */
    function _generateTraitCombo(
        uint256[5] memory character,
        uint256[3] memory head,
        uint256[6] memory clothing,
        uint256[6] memory accessories,
        uint256[2] memory items
    ) internal pure returns (uint256) {
        uint256 traits = character[0];
        traits |= character[1] << 10;
        traits |= character[2] << 20;
        traits |= character[3] << 30;
        traits |= character[4] << 40;
        traits |= head[0] << 50;
        traits |= head[1] << 60;
        traits |= head[2] << 70;
        traits |= clothing[0] << 80;
        traits |= clothing[1] << 90;
        traits |= clothing[2] << 100;
        traits |= clothing[3] << 110;
        traits |= clothing[4] << 120;
        traits |= clothing[5] << 130;
        traits |= accessories[0] << 140;
        traits |= accessories[1] << 150;
        traits |= accessories[2] << 160;
        traits |= accessories[3] << 170;
        traits |= accessories[4] << 180;
        traits |= accessories[5] << 190;
        traits |= items[0] << 200;
        traits |= items[1] << 210;
        return traits;
    }
}