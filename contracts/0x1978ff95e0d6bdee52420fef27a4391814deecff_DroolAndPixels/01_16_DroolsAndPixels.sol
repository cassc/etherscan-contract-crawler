//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {NFTDescriptor} from "./NFTDescriptor.sol";
import {IDroolsAndPixels} from "./interfaces/IDroolsAndPixels.sol";

contract DroolAndPixels is IDroolsAndPixels, ERC721, Ownable {
  using Strings for uint256;
  using SafeMath for uint256;

  mapping(uint256 => string[]) public override palettes;
  mapping(uint256 => bytes) public override seeds;
  mapping(uint256 => string) public override names;
  mapping(uint256 => uint8) public override backgroundIndex;
  mapping(uint256 => uint16[]) public override animatedPixels;
  string[] public override backgrounds;
  uint256 private _totalSupply;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _addColorToPalette(uint256 _paletteIndex, string calldata _color) internal {
    palettes[_paletteIndex].push(_color);
  }

  function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner {
    for (uint256 i = 0; i < _backgrounds.length; i++) {
      _addBackground(_backgrounds[i]);
    }
  }

  function _addBackground(string calldata _background) internal {
    backgrounds.push(_background);
  }

  function mintDrool(
    uint256 tokenId,
    string calldata name,
    bytes memory seed,
    uint8 bgColorIndex,
    string[] calldata colors,
    uint16[] calldata animatedPixel,
    address toAddress
  ) public override onlyOwner {
    require(palettes[tokenId].length + colors.length <= 256, "Palettes can only hold 256 colors");
    for (uint256 i = 0; i < colors.length; i++) {
      _addColorToPalette(tokenId, colors[i]);
    }
    names[tokenId] = name;
    seeds[tokenId] = seed;
    animatedPixels[tokenId] = animatedPixel;
    backgroundIndex[tokenId] = bgColorIndex;
    _totalSupply++;
    _safeMint(toAddress, tokenId);
    emit DroolMinted(tokenId, name, seed, bgColorIndex, colors, animatedPixel, toAddress);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, IDroolsAndPixels) returns (string memory) {
    require(_exists(tokenId), "NounsToken: URI query for nonexistent token");
    return dataURI(tokenId);
  }

  /**
   * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Nouns DAO noun.
   */
  function dataURI(uint256 tokenId) public view override returns (string memory) {
    string memory droolId = tokenId.toString();
    string memory name = string(abi.encodePacked("Drool ", names[tokenId], " #", droolId));
    string memory description = string(abi.encodePacked("Drools & Pixels #", droolId));
    return genericDataURI(name, description, tokenId);
  }

  /**
   * @notice Given a name, description, and seed, construct a base64 encoded data URI.
   */
  function genericDataURI(
    string memory name,
    string memory description,
    uint256 tokenId
  ) public view returns (string memory) {
    NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
      name: name,
      description: description,
      parts: seeds[tokenId],
      background: backgrounds[backgroundIndex[tokenId]],
      animatedPixels: animatedPixels[tokenId]
    });
    return NFTDescriptor.constructTokenURI(params, palettes[tokenId]);
  }
}