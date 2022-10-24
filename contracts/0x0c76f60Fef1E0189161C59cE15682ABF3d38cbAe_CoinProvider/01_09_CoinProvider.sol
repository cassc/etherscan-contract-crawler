// SPDX-License-Identifier: MIT

/*
 * NounsAssetProvider is a wrapper around NounsDescriptor so that it offers
 * various characters as assets to compose (not individual parts).
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import "assetprovider.sol/IAssetProvider.sol";
import "randomizer.sol/Randomizer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import "hardhat/console.sol";

/**
 * MultiplexProvider create a new asset provider from another asset provider,
 * which draws multiple assets with the same set of provider-specific properties.
 */
contract CoinProvider is IAssetProvider, IERC165, Ownable {
  using Strings for uint32;
  using Strings for uint256;
  using Randomizer for Randomizer.Seed;

  IAssetProvider public provider;
  string color;

  constructor(IAssetProvider _provider, string memory _color) {
    provider = _provider;
    color = _color;
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
    return ProviderInfo(string(abi.encodePacked(info.key, "_coin")), string(abi.encodePacked(info.name, " Coin")), this);
  }

  function totalSupply() external view override returns(uint256) {
    return provider.totalSupply(); 
  }

  function processPayout(uint256 _assetId) external override payable {
    provider.processPayout{value:msg.value}(_assetId);
  }

  function generateTraits(uint256 _assetId) external view returns (string memory traits) {
    traits = provider.generateTraits(_assetId);
  }

  function generateSVGPart(uint256 _assetId) external view override returns(string memory svgPart, string memory tag) {
    (svgPart, tag) = provider.generateSVGPart(_assetId);
    svgPart = string(abi.encodePacked(svgPart,    
      '<g id="', tag, '_coin">'
      '<circle cx="511" cy="511" r="511" />'
      '<use href="#', tag, '" fill="', color, '"/>'
      '</g>'));
    tag = string(abi.encodePacked(tag, '_coin'));  
  }
}