// SPDX-License-Identifier: MIT

/*
 * NounsAssetProvider is a wrapper around NounsDescriptor so that it offers
 * various characters as assets to compose (not individual parts).
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IAssetProvider } from './interfaces/IAssetProvider.sol';
import { IAssetProviderEx } from './interfaces/IAssetProviderEx.sol';
import "randomizer.sol/Randomizer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import "hardhat/console.sol";

/**
 * MultiplexProvider create a new asset provider from another asset provider,
 * which draws multiple assets with the same set of provider-specific properties.
 */
contract MultiplexProvider is IAssetProvider, IERC165, Ownable {
  using Strings for uint32;
  using Strings for uint256;
  using Randomizer for Randomizer.Seed;

  string providerKey;
  string providerName;

  uint constant schemeCount = 15;
  uint constant colorCount = 5;

  IAssetProviderEx public provider;

  constructor(IAssetProviderEx _provider, string memory _key, string memory _name) {
    provider = _provider;
    providerKey = _key;
    providerName = _name;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IAssetProvider).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  function getOwner() external override view returns (address) {
    return owner();
  }

  function getProviderInfo() external view override returns(ProviderInfo memory) {
    return ProviderInfo(providerKey, providerName, this);
  }

  function totalSupply() external pure override returns(uint256) {
    return 0; 
  }

  function processPayout(uint256 _assetId) external override payable {
    provider.processPayout{value:msg.value}(_assetId);
  }

  function getColorScheme(Randomizer.Seed memory _seed, uint256 _schemeIndex) internal pure returns(Randomizer.Seed memory seed, string[] memory scheme) {
    string[colorCount][schemeCount] memory schemes = [
      ["FFE33A", "7FAE2E", "B1661A", "DB3F14", "F9BE02"], // genki
      ["DBF8FF", "C8FFC3", "FFB86D", "FFC6B6", "FFF4BD"], // pastel
      ["005bbb", "0072ea", "258fff", "ffd500", "ffe040"], // ukraine
      ["5f7de8", "d179b9", "e6b422", "38b48b", "fef4f4"], // nippon
      ["B51802", "05933A", "0B7B48", "634D2D", "A6AAAE"], // Xmas
      ["E9B4DB", "6160B0", "EB77A6", "3E3486", "E23D80"], // love
      ["2c4269", "eabc67", "4b545e", "f98650", "0d120f"], // edo
      ["EDC9AF", "A0E2BD", "53CBCF", "0DA3BA", "046E94"], // beach
      ["FFE889", "88E7C5", "53BD99", "01767D", "034F4D"], // jungle
      ["744981", "CB6573", "FFAC00", "ED3F37", "0577A1"], // backson
      ["E28199", "D6637E", "ADDF82", "5A421B", "392713"], // sakura
      ["159F67", "66CA96", "EBFFF4", "F9BDB3", "F39385"], // spring
      ["F9CC6C", "FD9A9C", "FEE4C6", "9DD067", "3D7F97"], // summer
      ["627AA3", "D8D0C5", "DAAE46", "7AAB9C", "9F4F4C"], // vintage
      ["5A261B", "C81125", "F15B4A", "FFAB63", "FADB6A"] // fall
    ];
    scheme = new string[](colorCount);
    uint offset;
    (seed, offset) = _seed.random(colorCount);
    for (uint i = 0; i < colorCount ; i++) {
      scheme[i] = schemes[_schemeIndex][(i + offset) % colorCount];
    }
  }

  function generateTraits(uint256 _assetId) external pure returns (string memory) {
    Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);
    uint schemeIndex;
    (seed, schemeIndex) = seed.random(schemeCount);
    string[schemeCount] memory colorNames = [
      "Genki", "Pastel", "Ukraine", "Nippon", "Xmas",
      "Love", "Edo", "Beach", "Jungle", "Backson", "Sakura", "Spring", "Summer", "Vintage", "Fall"
    ];
    return string(abi.encodePacked(
      '{'
        '"trait_type":"Color Scheme",'
        '"value":"', colorNames[schemeIndex], '"' 
      '}'
    ));
  }

  function generateSVGPart(uint256 _assetId) external view override returns(string memory svgPart, string memory tag) {
    Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);
    uint schemeIndex;
    (seed, schemeIndex) = seed.random(schemeCount);

    string[] memory scheme;
    (seed, scheme) = getColorScheme(seed, schemeIndex);

    uint256 props;
    (seed, props) = provider.generateRandomProps(seed);
    
    bytes memory defs;
    bytes memory body;
    tag = string(abi.encodePacked(providerKey, _assetId.toString()));
    string memory tagPart;

    seed = Randomizer.Seed(_assetId, 0);
    for (uint i = 0; i < scheme.length * 10; i++) {
      tagPart = string(abi.encodePacked(tag, "_", i.toString()));
      (seed, svgPart) = provider.generateSVGPartWithProps(seed, props, tagPart);
      defs = abi.encodePacked(defs, svgPart);
      body = abi.encodePacked(body, '<use href="#', tagPart, '" fill="#', scheme[i / 10]);

      uint size;
      (seed, size) = seed.random(400);
      size += 100;
      uint margin = (1024 - 1024 * size / 1000) / 2;
      uint x;
      uint y;
      (seed, x) = seed.randomize(margin, 100);
      (seed, y) = seed.randomize(margin, 100);
      body = abi.encodePacked(body, '" transform="translate(',
        x.toString(), ',', y.toString(),
        ') scale(0.',size.toString(),', 0.',size.toString(),')" />\n');
    }

    svgPart = string(abi.encodePacked(
      defs,
      '<g id="', tag, '">\n',
      body,
      '</g>\n'
    ));
  }
}