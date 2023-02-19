// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ownable
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IOnChainMetadata.sol";
import "../libraries/MetadataUtils.sol";

import {MTE} from "./MTE.sol";

contract PostRevealOnChainMetadata is IOnChainMetadata, Ownable {
  using Strings for uint256;

  string internal _base64Data;
  string internal _glitchedBase64Data;
  string internal _name;
  string internal _description;
  string internal _external_url;
  string internal _background_color;

  uint256 public randomBlockNumber;
  uint256 public randomNumber;
  uint256 public immutable delayNumber;

  constructor(
    string memory base64Data_,
    string memory glitchedBase64Data_,
    string memory name_,
    string memory description_,
    string memory external_url_,
    string memory background_color_,
    uint256 delayNumber_
  ) {
    _base64Data = base64Data_;
    _glitchedBase64Data = glitchedBase64Data_;
    _name = name_;
    _description = description_;
    _external_url = external_url_;
    _background_color = background_color_;

    delayNumber = delayNumber_;

    randomBlockNumber = block.number + (uint8(block.prevrandao) % delayNumber);
  }

  function callRandom() external onlyOwner {
    require(block.number >= randomBlockNumber, "Not yet");
    require(randomNumber == 0, "Already called");

    randomNumber = uint256(
      keccak256(abi.encodePacked(blockhash(randomBlockNumber), block.prevrandao, block.coinbase))
    );
  }

  function generateBase64(uint256 tokenId) external view returns (string memory) {
    return _base64Data;
  }

  function tokenImageDataURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked("data:image/svg+xml;base64,", _base64Data));
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    string memory dataURI = MetadataUtils.tokenMetadataToString(
      TokenMetadata(
        _name,
        _description,
        tokenImageDataURI(tokenId),
        _external_url,
        _background_color,
        getAttributes(tokenId, MTE(msg.sender).tokenTypes(tokenId))
      )
    );

    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(dataURI))));
  }

  function getAttributes(
    uint256 tokenId,
    uint256 tokenType
  ) internal view returns (Attribute[] memory attributes) {
    bool glitched = isGlitched(tokenId, tokenType);

    if (glitched) {
      attributes = new Attribute[](2);
      if (tokenType == 0) {
        attributes = new Attribute[](0);
      } else if (tokenType == 1) {
        attributes[0] = Attribute("Class", "The Chosen One");
        attributes[1] = Attribute("State ", "Corrupted");
      } else if (tokenType == 2) {
        attributes[0] = Attribute("Class", "Free Mintooor");
        attributes[1] = Attribute("State ", "Corrupted");
      } else if (tokenType == 3) {
        attributes[0] = Attribute("Class", "Big Money Spendooor");
        attributes[1] = Attribute("State ", "Corrupted");
      }
    } else {
      attributes = new Attribute[](2);
      if (tokenType == 0) {
        attributes = new Attribute[](0);
      } else if (tokenType == 1) {
        attributes[0] = Attribute("Class", "The Chosen One");
        attributes[1] = Attribute("State ", "Rugged");
      } else if (tokenType == 2) {
        attributes[0] = Attribute("Class", "Free Mintooor");
        attributes[1] = Attribute("State ", "Rugged");
      } else if (tokenType == 3) {
        attributes[0] = Attribute("Class", "Big Money Spendooor");
        attributes[1] = Attribute("State ", "Rugged");
      }
    }
  }

  function isGlitched(uint256 tokenId, uint256 tokenType) internal view returns (bool) {
    require(randomNumber != 0, "Random number not yet generated");
    return uint256(keccak256(abi.encodePacked(tokenId, tokenType, randomNumber))) % 100 == 0;
  }
}