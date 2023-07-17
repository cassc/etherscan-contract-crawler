// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import 'base64-sol/base64.sol';

//
//▄████████    ▄████████     ███         ███      ▄█          ▄████████   ▄▄▄▄███▄▄▄▄      ▄████████ ███▄▄▄▄       ███        ▄████████
//███    ███   ███    ███ ▀█████████▄ ▀█████████▄ ███         ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ ███▀▀▀██▄ ▀█████████▄   ███    ███
//███    █▀    ███    █▀     ▀███▀▀██    ▀███▀▀██ ███         ███    █▀  ███   ███   ███   ███    █▀  ███   ███    ▀███▀▀██   ███    █▀
//███         ▄███▄▄▄         ███   ▀     ███   ▀ ███        ▄███▄▄▄     ███   ███   ███  ▄███▄▄▄     ███   ███     ███   ▀   ███
//▀███████████ ▀▀███▀▀▀         ███         ███     ███       ▀▀███▀▀▀     ███   ███   ███ ▀▀███▀▀▀     ███   ███     ███     ▀███████████
//███   ███    █▄      ███         ███     ███         ███    █▄  ███   ███   ███   ███    █▄  ███   ███     ███              ███
//▄█    ███   ███    ███     ███         ███     ███▌    ▄   ███    ███ ███   ███   ███   ███    ███ ███   ███     ███        ▄█    ███
//▄████████▀    ██████████    ▄████▀      ▄████▀   █████▄▄██   ██████████  ▀█   ███   █▀    ██████████  ▀█   █▀     ▄████▀    ▄████████▀
//▀

// @author zeth

// @notice This contract is heavily inspired by Dom Hofmann's Loot Project with game design from Sid Meirs Civilisation, DND, Settlers of Catan & Age of Empires.

// Settlements allows for the creation of settlements of which users have 5 turns to create their perfect civ.
// Randomise will pseduo randomly assign a settlement a new set of attributes & increase their turn count.
// An allocation of 100 settlements are reserved for owner & future expansion packs

contract Settlements is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {

    constructor() ERC721("Settlements", "STL") {}

    struct Attributes {
        uint8 size;
        uint8 spirit;
        uint8 age;
        uint8 resource;
        uint8 morale;
        uint8 government;
        uint8 turns;
    }

    string[] private _sizes = ['Camp', 'Hamlet', 'Village', 'Town', 'District', 'Precinct', 'Capitol', 'State'];
    string[] private _spirits = ['Earth', 'Fire', 'Water', 'Air', 'Astral'];
    string[] private _ages = ['Ancient', 'Classical', 'Medieval', 'Renaissance', 'Industrial', 'Modern', 'Information', 'Future'];
    string[] private _resources = ['Iron', 'Gold', 'Silver', 'Wood', 'Wool', 'Water', 'Grass', 'Grain'];
    string[] private _morales = ['Expectant', 'Enlightened', 'Dismissive', 'Unhappy', 'Happy', 'Undecided', 'Warring', 'Scared', 'Unruly', 'Anarchist'];
    string[] private _governments = ['Democracy', 'Communism', 'Socialism', 'Oligarchy', 'Aristocracy', 'Monarchy', 'Theocracy', 'Colonialism', 'Dictatorship'];
    string[] private _realms = ['Genesis', 'Valhalla', 'Keskella', 'Shadow', 'Plains', 'Ends'];

    mapping(uint256 => Attributes) private attrIndex;

    function indexFor(string memory input, uint256 length) internal pure returns (uint256){
        return uint256(keccak256(abi.encodePacked(input))) % length;
    }

    function _getRandomSeed(uint256 tokenId, string memory seedFor) internal view returns (string memory) {
        return string(abi.encodePacked(seedFor, Strings.toString(tokenId), block.timestamp, block.difficulty));
    }

    function generateAttribute(string memory salt, string[] memory items) internal pure returns (uint8){
        return uint8(indexFor(string(salt), items.length));
    }

    function _makeParts(uint256 tokenId) internal view returns (string[15] memory){
        string[15] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.txt { fill: black; font-family: monospace; font-size: 12px;}</style><rect width="100%" height="100%" fill="white" /><text x="10" y="20" class="txt">';
        parts[1] = _sizes[attrIndex[tokenId].size];
        parts[2] = '</text><text x="10" y="40" class="txt">';
        parts[3] = _spirits[attrIndex[tokenId].spirit];
        parts[4] = '</text><text x="10" y="60" class="txt">';
        parts[5] = _ages[attrIndex[tokenId].age];
        parts[6] = '</text><text x="10" y="80" class="txt">';
        parts[7] = _resources[attrIndex[tokenId].resource];
        parts[8] = '</text><text x="10" y="100" class="txt">';
        parts[9] = _morales[attrIndex[tokenId].morale];
        parts[10] = '</text><text x="10" y="120" class="txt">';
        parts[11] = _governments[attrIndex[tokenId].government];
        parts[12] = '</text><text x="10" y="140" class="txt">';
        parts[13] = _realms[attrIndex[tokenId].turns];
        parts[14] = '</text></svg>';
        return parts;
    }

    function _makeAttributeParts(string[15] memory parts) internal pure returns (string[15] memory){
        string[15] memory attrParts;
        attrParts[0] = '[{ "trait_type": "Size", "value": "';
        attrParts[1] = parts[1];
        attrParts[2] = '" }, { "trait_type": "Spirit", "value": "';
        attrParts[3] = parts[3];
        attrParts[4] = '" }, { "trait_type": "Age", "value": "';
        attrParts[5] = parts[5];
        attrParts[6] = '" }, { "trait_type": "Resource", "value": "';
        attrParts[7] = parts[7];
        attrParts[8] = '" }, { "trait_type": "Morale", "value": "';
        attrParts[9] = parts[9];
        attrParts[10] = '" }, { "trait_type": "Government", "value": "';
        attrParts[11] = parts[11];
        attrParts[12] = '" }, { "trait_type": "Realm", "value": "';
        attrParts[13] = parts[13];
        attrParts[14] = '" }]';
        return attrParts;
    }

    function tokenURI(uint256 tokenId) virtual override public view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");

        string[15] memory parts = _makeParts(tokenId);
        string[15] memory attributesParts = _makeAttributeParts(parts);
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        string memory atrrOutput = string(abi.encodePacked(attributesParts[0], attributesParts[1], attributesParts[2], attributesParts[3], attributesParts[4], attributesParts[5], attributesParts[6], attributesParts[7], attributesParts[8]));
        atrrOutput = string(abi.encodePacked(atrrOutput, attributesParts[9], attributesParts[10], attributesParts[11], attributesParts[12], attributesParts[13], attributesParts[14]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Settlement #', Strings.toString(tokenId), '", "description": "Settlements are a turn based civilisation simulator stored entirely on chain, go forth and conquer.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"', ',"attributes":', atrrOutput, '}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function randomiseAttributes(uint256 tokenId, uint8 turn) internal {
        attrIndex[tokenId].size = generateAttribute(_getRandomSeed(tokenId, 'size'), _sizes);
        attrIndex[tokenId].spirit = generateAttribute(_getRandomSeed(tokenId, 'spirit'), _spirits);
        attrIndex[tokenId].age = generateAttribute(_getRandomSeed(tokenId, 'age'), _ages);
        attrIndex[tokenId].resource = generateAttribute(_getRandomSeed(tokenId, 'resource'), _resources);
        attrIndex[tokenId].morale = generateAttribute(_getRandomSeed(tokenId, 'morale'), _morales);
        attrIndex[tokenId].government = generateAttribute(_getRandomSeed(tokenId, 'government'), _governments);
        attrIndex[tokenId].turns = turn;
    }


    function randomise(uint256 tokenId) public nonReentrant {
        require(_exists(tokenId) && msg.sender == ownerOf(tokenId) && attrIndex[tokenId].turns < 5, 'Settlement turns over');
        randomiseAttributes(tokenId, uint8(SafeMath.add(attrIndex[tokenId].turns, 1)));
    }

    function settle(uint256 tokenId) public nonReentrant {
        require(!_exists(tokenId) && tokenId > 0 && tokenId < 9901, "Settlement id is invalid");
        randomiseAttributes(tokenId, 0);
        _safeMint(msg.sender, tokenId);
    }

    function settleForOwner(uint256 tokenId) public nonReentrant onlyOwner {
        require(!_exists(tokenId) && tokenId > 9900 && tokenId < 10001, "Settlement id is invalid");
        randomiseAttributes(tokenId, 0);
        _safeMint(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}