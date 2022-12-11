// SPDX-License-Identifier: MIT

/*
 * DotNounsProvider generates a "dot version" of Nouns characters.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import 'assetprovider.sol/IAssetProvider.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '../providers/NounsAssetProviderV2.sol';
import '../packages/graphics/SVG.sol';
import '../packages/graphics/SVGFilter.sol';

contract PaperNounsProvider is IAssetProvider, IERC165, Ownable {
  using Vector for Vector.Struct;
  using Path for uint[];
  using SVG for SVG.Element;

  NounsAssetProviderV2 public provider;

  constructor(NounsAssetProviderV2 _provider) {
    provider = _provider;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAssetProvider).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  function getOwner() external view override returns (address) {
    return owner();
  }

  function getProviderInfo() external view override returns (ProviderInfo memory) {
    ProviderInfo memory info = provider.getProviderInfo();
    return
      ProviderInfo(string(abi.encodePacked(info.key, '_paper')), string(abi.encodePacked(info.name, ' Paper')), this);
  }

  function totalSupply() external view override returns (uint256) {
    return provider.getNounsTotalSuppy();
  }

  function processPayout(uint256 _assetId) external payable override {
    provider.processPayout{ value: msg.value }(_assetId);
  }

  function generateTraits(uint256 _assetId) external view returns (string memory traits) {
    traits = provider.generateTraits(_assetId);
  }

  function generateSVGPart(uint256 _assetId) external view override returns (string memory svgPart, string memory tag) {
    string memory tag0;
    (svgPart, tag0) = provider.getNounsSVGPart(_assetId);
    tag = string(abi.encodePacked(tag, '_paper'));

    // We need to use this work-around (1024 circles) because Safari browser is not able to
    // render <pattern> correctly.
    svgPart = string(
      SVG
        .list(
          [
            SVG.element(bytes(svgPart)),
            SVGFilter.roughPaper("roughPaper"),
            SVG.group([SVG.rect().fill('#d5d7e1'), SVG.use(tag0).mask('dot32mask')])
              .filter("roughPaper")
              .id(tag)
          ]
        )
        .svg()
    );
  }
}