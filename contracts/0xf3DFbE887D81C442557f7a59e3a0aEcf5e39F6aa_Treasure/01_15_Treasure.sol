// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './Base64.sol';

contract Treasure is ERC721Enumerable, ReentrancyGuard, Ownable {

  string[] private assetOne = [
    "Emerald",
    "Gold Coin",
    "Silver Penny",
    "Half-Penny",
    "Quarter-Penny",
    "Pearl",
    "Red Rupee",
    "Diamond",
    "Dragon Tail",
    "Beetle-wing",
    "Ox",
    "Donkey",
    "Score of Ivory",
    "Unbreakable Pocketwatch",
    "Grain",
    "Lumber"
  ];

  string[] private assetTwo = [
    "Emerald",
    "Gold Coin",
    "Silver Penny",
    "Half-Penny",
    "Quarter-Penny",
    "Pearl",
    "Red Rupee",
    "Diamond",
    "Dragon Tail",
    "Beetle-wing",
    "Ox",
    "Donkey",
    "Common Feather",
    "Red Feather"
    "Snow White Feather",
    "Thread of Divine Silk",
    "Mollusk Shell",
    "Grain",
    "Lumber"
  ];

  string[] private assetThree = [
    "Emerald",
    "Gold Coin",
    "Silver Penny",
    "Half-Penny",
    "Quarter-Penny",
    "Pearl",
    "Red Rupee",
    "Diamond",
    "Dragon Tail",
    "Beetle-wing",
    "Ox",
    "Donkey",
    "Common Feather",
    "Red Feather",
    "Immovable Stone",
    "Divine Hourglass",
    "Bag of Rare Mushrooms"
  ];

  string[] private assetFour = [
    "Emerald",
    "Gold Coin",
    "Silver Penny",
    "Half-Penny",
    "Quarter-Penny",
    "Pearl",
    "Red Rupee",
    "Diamond",
    "Dragon Tail",
    "Beetle-wing",
    "Ox",
    "Donkey",
    "Blue Rupee",
    "Framed Butterfly",
    "Small Bird",
    "Common Relic"
  ];

  string[] private assetFive = [
    "Emerald",
    "Gold Coin",
    "Silver Penny",
    "Half-Penny",
    "Quarter-Penny",
    "Pearl",
    "Red Rupee",
    "Diamond",
    "Dragon Tail",
    "Beetle-wing",
    "Donkey",
    "Pot of Gold",
    "Witches Broom",
    "Divine Mask"
  ];

  string[] private assetSix = [
    "Emerald",
    "Gold Coin",
    "Silver Penny",
    "Half-Penny",
    "Quarter-Penny",
    "Pearl",
    "Red Rupee",
    "Diamond",
    "Dragon Tail",
    "Beetle-wing",
    "Blue Rupee",
    "Jar of Fairies",
    "Favor from the Gods",
    "Common Bead",
    "Cow"
  ];

  string[] private assetSeven = [
    "Emerald",
    "Gold Coin",
    "Silver Penny",
    "Half-Penny",
    "Quarter-Penny",
    "Pearl",
    "Red Rupee",
    "Diamond",
    "Dragon Tail",
    "Beetle-wing",
    "Green Rupee",
    "Blue Rupee",
    "Common Relic",
    "Ivory Breastpin",
    "Carrage",
    "Military Stipend"
  ];

  string[] private assetEight = [
    "Emerald",
    "Gold Coin",
    "Silver Penny",
    "Half-Penny",
    "Quarter-Penny",
    "Pearl",
    "Red Rupee",
    "Diamond",
    "Dragon Tail",
    "Beetle-wing",
    "Honeycomb",
    "Green Rupee",
    "Blue Rupee",
    "Grin",
    "Bait for Monsters",
    "Castle",
    "Bottomless Elixir",
    "Common Relic",
    "Ancient Relic",
    "Cap of Invisibility"
  ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getAsset1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ASSETONE", assetOne);
    }

    function getAsset2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ASSETTWO", assetTwo);
    }

    function getAsset3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ASSETTHREE", assetThree);
    }

    function getAsset4(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ASSETFOUR", assetFour);
    }

    function getAsset5(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ASSETFIVE", assetFive);
    }

    function getAsset6(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ASSETSIX", assetSix);
    }

    function getAsset7(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ASSETSEVEN", assetSeven);
    }

    function getAsset8(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ASSETEIGHT", assetEight);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        return sourceArray[rand % sourceArray.length];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getAsset1(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getAsset2(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getAsset3(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getAsset4(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getAsset5(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getAsset6(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getAsset7(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getAsset8(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 9000, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256[] calldata tokenIds) public nonReentrant onlyOwner {
        address account = owner();

        for (uint i; i < tokenIds.length; i++) {
          uint tokenId = tokenIds[i];
          require(tokenId > 8999 && tokenId < 10001, "Token ID invalid");
          _safeMint(account, tokenId);
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor() ERC721("Treasure", "TREASURE") Ownable() {}
}