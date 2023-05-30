//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "base64-sol/base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Cable.sol";

/// @title CABLE Metadata
/// @notice https://cable.folia.app
/// @author @okwme / okw.me, artwork by @joanheemskerk / https://w3b4.net/cable-/
/// @dev Generates the metadata as JSON String and encodes it with base64 and data:application/json;base64,

contract Metadata is Ownable {
  string[17] internal regions = [
    "Africa - Asia",
    "Asia - Australia",
    "Europe - Africa",
    "Europe - Africa - Asia",
    "Europe - Asia",
    "Intra - Africa",
    "Intra - Asia",
    "Intra - Australia",
    "Intra - Europe",
    "Intra - North Americas",
    "Intra - South Americas",
    "North - South Americas",
    "Trans - Indian Ocean",
    "Trans - North Atlantic",
    "Trans - North Pacific",
    "Trans - South Atlantic",
    "Trans - South Pacific"
  ];
  // note: redundant cableId is necessary to ensure correct order on upload in case some fail in the process
  struct CableData {
    uint256 cableId;
    uint256 regionIndex;
    string name;
    string path;
    uint256 length;
  }
  mapping(uint256 => CableData) internal cables;
  uint256 public totalCables;

  constructor() {}

  function addCables(CableData[] memory cables_) public onlyOwner {
    if (cables_.length > 0) {
      require(cables[cables_[0].cableId].cableId == 0, "ALREADY ADDED THIS CHUNK");
    } else {
      revert("NO CABLES");
    }
    for (uint256 i = 0; i < cables_.length; i++) {
      cables[cables_[i].cableId] = cables_[i];
      totalCables += 1;
    }
  }

  function updateCables(CableData[] memory cables_) public onlyOwner {
    for (uint256 i = 0; i < cables_.length; i++) {
      cables[cables_[i].cableId] = cables_[i];
      totalCables += 1;
    }
  }

  function getCable(
    uint256 tokenId
  ) public view existsModifier(tokenId) returns (uint256 regionIndex, string memory name, string memory path) {
    CableData memory cable = cables[tokenId];
    return (cable.regionIndex, cable.name, cable.path);
  }

  /**
   * @dev Throws if id doesn't exist
   */
  modifier existsModifier(uint256 id) {
    require(exists(id), "DOES NOT EXIST");
    _;
  }

  function exists(uint256 id) public view returns (bool) {
    return Cable(cableAddress).ownerOf(id) != address(0);
  }

  address cableAddress;

  function setCable(address cableAddress_) public onlyOwner {
    cableAddress = cableAddress_;
  }

  /// @dev generates the metadata
  /// @param tokenId the tokenId
  function getMetadata(uint256 tokenId) public view existsModifier(tokenId) returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              getName(tokenId),
              '", "description": "The world\'s Submarine Cable System, expressed as 545 on-chain, .SVG-animations by artist Joan Heemskerk (JODI) ~ presented by folia.", "image": "',
              getSVG(tokenId),
              '",',
              '"attributes": ',
              getAttributes(tokenId),
              "}"
            )
          )
        )
      );
  }

  /// @dev generates the Name as a string
  /// @param tokenId the tokenId
  function getName(uint256 tokenId) internal view existsModifier(tokenId) returns (string memory) {
    return cables[tokenId].name;
  }

  /// @dev function to generate a SVG String
  function getSVG(uint256 tokenId) public view existsModifier(tokenId) returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(
            abi.encodePacked(
              '<?xml version="1.0" encoding="utf-8"?> <svg xmlns="http://www.w3.org/2000/svg"  height="100%" width="100%" viewBox="0 0 600 600" style="background: #ffffff;" preserveAspectRatio="meet"><style>.name {fill: #000000;font-size: 14px;font-family: "Verdana",sans-serif;}path{fill: none;stroke: #000000;stroke-width: 100;stroke-dasharray: 1;animation: dash 1s linear infinite;}@keyframes dash { to {stroke-dashoffset: 100;}}</style>',
              getPath(tokenId),
              '<text x="50" y="550" class="name">',
              getName(tokenId),
              "</text></svg>"
            )
          )
        )
      );
  }

  function getPath(uint256 tokenId) internal view returns (string memory) {
    return cables[tokenId].path;
  }

  function updateCable(
    uint256 tokenId,
    uint256 regionIndex,
    string memory path,
    string memory name,
    uint256 length
  ) public onlyOwner {
    cables[tokenId].regionIndex = regionIndex;
    cables[tokenId].path = path;
    cables[tokenId].name = name;
    cables[tokenId].length = length;
  }

  /// @dev generates the attributes as JSON String
  function getAttributes(uint256 tokenId) internal view returns (string memory) {
    return
      string(
        abi.encodePacked(
          "[",
          '{"trait_type":"Region","value":"',
          regions[cables[tokenId].regionIndex],
          '"}, {"trait_type":"Length","value":"',
          Strings.toString(cables[tokenId].length),
          'km"}]'
        )
      );
  }
}