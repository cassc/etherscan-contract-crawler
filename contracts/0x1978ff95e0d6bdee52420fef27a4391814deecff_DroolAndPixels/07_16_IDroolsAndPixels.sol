// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

/*******************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░██░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░████░░░░██░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░████░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░████░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░██░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░██░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 ******************************/

pragma solidity ^0.8.6;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDroolsAndPixels is IERC721 {
  event DroolMinted(
    uint256 indexed tokenId,
    string name,
    bytes seed,
    uint8 bgColorIndex,
    string[] colors,
    uint16[] animatedPixel,
    address toAddress
  );

  function palettes(uint256 paletteIndex, uint256 colorIndex) external view returns (string memory);

  function backgrounds(uint256 index) external view returns (string memory);

  function seeds(uint256 index) external view returns (bytes memory);

  function names(uint256 index) external view returns (string memory);

  function backgroundIndex(uint256 index) external view returns (uint8);

  function animatedPixels(uint256 tokenId, uint256 index) external view returns (uint16);

  function addManyBackgrounds(string[] calldata _backgrounds) external;

  function mintDrool(
    uint256 tokenId,
    string calldata name,
    bytes memory seed,
    uint8 bgColorIndex,
    string[] calldata colors,
    uint16[] calldata animatedPixel,
    address toAddress
  ) external;

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function dataURI(uint256 tokenId) external returns (string memory);
}