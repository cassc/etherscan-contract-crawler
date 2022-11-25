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
import "../interfaces/IColorSchemes.sol";
import "../interfaces/ILayoutGenerator.sol";
import "fully-on-chain.sol/SVG.sol";
import '../interfaces/IOnChainWallet.sol';

/**
 * MultiplexProvider create a new asset provider from another asset provider,
 * which draws multiple assets with the same set of provider-specific properties.
 */
contract AlphabetProvider is IAssetProvider, IERC165, Ownable {
  using Strings for uint256;
  using Randomizer for Randomizer.Seed;
  using BytesArray for bytes[];
  using SVG for SVG.Element;
  using TX for string;

  ILayoutGenerator public generator;
  IColorSchemes public colorSchemes;
  IFontProvider public font;
  IOnChainWallet public receiver; // proxy to pNouns wallet (0x8AE80e0B44205904bE18869240c2eC62D2342785)

  constructor(IFontProvider _font, ILayoutGenerator _generator, IColorSchemes _colorSchemes, IOnChainWallet _receiver) {
    font = _font;
    generator = _generator;
    colorSchemes = _colorSchemes;
    receiver = _receiver;
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
    return ProviderInfo("alphabet", "Alphabet", this);
  }

  function totalSupply() external pure override returns(uint256) {
    return 0;
  }

  function setReceiver(IOnChainWallet _receiver) external onlyOwner {
    receiver = _receiver;
  }

  function processPayout(uint256 _assetId) external override payable {
    uint amount = msg.value / 2;
    receiver.deposite{value:amount}();
    emit Payout("alphabet", _assetId, payable(address(receiver)), amount);

    amount = msg.value - amount; // eliminating round error
    font.processPayout{value:amount / 5}(); // 10% distribution to the font provider

    amount = amount - amount / 5;
    address payable payableTo = payable(owner());
    payableTo.transfer(amount);
    emit Payout("alphabet", _assetId, payableTo, amount);
  }

  function generateTraits(uint256 _assetId) external view returns (string memory) {
    return colorSchemes.generateTraits(_assetId);
  }

  function generateSVGPart(uint256 _assetId) external view override returns(string memory svgPart, string memory tag) {
    Randomizer.Seed memory seed;
    string[] memory scheme;
    (seed, scheme) = colorSchemes.getColorScheme(_assetId);
    tag = string(abi.encodePacked("alphabet", _assetId.toString()));

    for (uint i=0; i<scheme.length; i++) {
      scheme[i] = string(abi.encodePacked('#', scheme[i]));      
    }

    ILayoutGenerator.Node[] memory nodes;
    (seed, nodes) = generator.generate(seed, 0 + 30 * 0x100 + 60 * 0x10000);

    SVG.Element[] memory parts = new SVG.Element[](nodes.length);
    bytes memory text = new bytes(1);
    bytes memory scrabble = bytes("AAAAAAAAABBCCDDDDEEEEEEEEEEEEFFGGGHHIIII"
                              "IIIIIJKLLLLMMNNNNNNOOOOOOPPQRRTTTTTTUUUUVVWWXYYZ");
    for (uint i = 0; i < nodes.length; i++) {
      ILayoutGenerator.Node memory node = nodes[i];
      uint index;
      (seed, index) = seed.random(scrabble.length);
      text[0] = scrabble[index];
      uint width = font.widthOf(string(text));
      width = ((1024 - width) / 2 * node.size) / 1024;
      parts[i] = SVG.group([
                    SVG.rect(int(node.x), int(node.y), node.size, node.size)
                      .fill(scheme[i % scheme.length]),
                    SVG.text(font, string(text))
                      .transform(TX.translate(int(node.x + width), int(node.y + node.size/10)).scale1000(node.size))]);
    }
    svgPart = string(SVG.group(parts).id(tag).fill("#222").svg());
  }
}