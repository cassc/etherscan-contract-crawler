// SPDX-License-Identifier: MIT

/*
 * DotNounsProvider generates a "dot version" of Nouns characters.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import "assetprovider.sol/IAssetProvider.sol";
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import "../providers/NounsAssetProvider.sol";
import "../packages/graphics/SVG.sol";

contract DotNounsProvider is IAssetProvider, IERC165, Ownable {
  using Vector for Vector.Struct;
  using Path for uint[];
  using SVG for SVG.Element;

  NounsAssetProvider public provider;

  constructor(NounsAssetProvider _provider) {
    provider = _provider;
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
    ProviderInfo memory info = provider.getProviderInfo();
    return ProviderInfo(string(abi.encodePacked(info.key, "_dot32")), string(abi.encodePacked(info.name, " Dot")), this);
  }

  function totalSupply() external view override returns(uint256) {
    return provider.getNounsTotalSuppy(); 
  }

  function processPayout(uint256 _assetId) external override payable {
    provider.processPayout{value:msg.value}(_assetId);
  }

  function generateTraits(uint256 _assetId) external view returns (string memory traits) {
    traits = provider.generateTraits(_assetId);
  }

  function generateSVGPart(uint256 _assetId) external view override returns(string memory svgPart, string memory tag) {
    string memory tag0;
    (svgPart, tag0) = provider.getNounsSVGPart(_assetId);
    tag = string(abi.encodePacked(tag, '_dot32'));

    // We need to use this work-around (1024 circles) because Safari browser is not able to
    // render <pattern> correctly. 
    svgPart = string(SVG.list([
      SVG.element(bytes(svgPart)),
      SVG.group([
        SVG.circle(16, 16, 16),
        SVG.circle(48, 16, 16),
        SVG.circle(80, 16, 16),
        SVG.circle(112, 16, 16)
      ]).id("dot32_4"),
      SVG.group([
        SVG.use("dot32_4"),
        SVG.use("dot32_4").transform("translate(128 0)"),
        SVG.use("dot32_4").transform("translate(256 0)"),
        SVG.use("dot32_4").transform("translate(384 0)"),
        SVG.use("dot32_4").transform("translate(512 0)"),
        SVG.use("dot32_4").transform("translate(640 0)"),
        SVG.use("dot32_4").transform("translate(768 0)"),
        SVG.use("dot32_4").transform("translate(896 0)")
      ]).id("dot32_32"),
      SVG.rect(), // filler to make the array size 8.
      SVG.group([
        SVG.use("dot32_32"),
        SVG.use("dot32_32").transform("translate(0 32)"),
        SVG.use("dot32_32").transform("translate(0 64)"),
        SVG.use("dot32_32").transform("translate(0 96)")
      ]).id("dot32_128"),
      SVG.group([
        SVG.use("dot32_128"),
        SVG.use("dot32_128").transform("translate(0 128)"),
        SVG.use("dot32_128").transform("translate(0 256)"),
        SVG.use("dot32_128").transform("translate(0 384)"),
        SVG.use("dot32_128").transform("translate(0 512)"),
        SVG.use("dot32_128").transform("translate(0 640)"),
        SVG.use("dot32_128").transform("translate(0 768)"),
        SVG.use("dot32_128").transform("translate(0 896)")
      ]).id("dot32_1024"),
      SVG.mask("dot32mask",
        SVG.list([
          SVG.rect().fill("black"),
          SVG.use("dot32_1024").fill("white")
        ])
      ),
      SVG.group([
        SVG.rect().fill("#d5d7e1"),
        SVG.use(tag0).mask("dot32mask")
      ]).id(tag)
    ]).svg());
  }
}