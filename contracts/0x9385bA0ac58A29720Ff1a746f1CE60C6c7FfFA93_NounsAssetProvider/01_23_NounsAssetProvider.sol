// SPDX-License-Identifier: MIT

/*
 * NounsAssetProvider is a wrapper around NounsDescriptor so that it offers
 * various characters as assets to compose (not individual parts).
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import { Base64 } from 'base64-sol/base64.sol';
import "assetprovider.sol/IAssetProvider.sol";
import "../external/nouns/interfaces/INounsDescriptor.sol";
import "../external/nouns/interfaces/INounsSeeder.sol";
import { NounsToken } from '../external/nouns/NounsToken.sol';

// IAssetProvider wrapper for composability
contract NounsAssetProvider is IAssetProvider, IERC165, Ownable {
  using Strings for uint256;

  string constant providerKey = "nouns";

  NounsToken public immutable nounsToken;
  INounsDescriptor public immutable descriptor;

  constructor(NounsToken _nounsToken, INounsDescriptor _descriptor) {
    nounsToken = _nounsToken;
    descriptor = _descriptor;
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
    return ProviderInfo(providerKey, "Nouns", this);
  }

  function generateSVGPart(uint256 _assetId) external view override returns(string memory svgPart, string memory tag) {
    uint256 backgroundCount = descriptor.backgroundCount();
    uint256 bodyCount = descriptor.bodyCount();
    uint256 accessoryCount = descriptor.accessoryCount();
    uint256 headCount = descriptor.headCount();
    uint256 glassesCount = descriptor.glassesCount();

    uint256 pseudorandomness = uint256(keccak256(abi.encodePacked(_assetId)));

    INounsSeeder.Seed memory seed = INounsSeeder.Seed({
        background: uint48(
            uint48(pseudorandomness) % backgroundCount
        ),
        body: uint48(
            uint48(pseudorandomness >> 48) % bodyCount
        ),
        accessory: uint48(
            uint48(pseudorandomness >> 96) % accessoryCount
        ),
        head: uint48(
            uint48(pseudorandomness >> 144) % headCount
        ),
        glasses: uint48(
            uint48(pseudorandomness >> 192) % glassesCount
        )
    });

    tag = string(abi.encodePacked(providerKey, _assetId.toString()));
    svgPart = svgForSeed(seed, tag);
  }

  function getNounsSVGPart(uint256 _assetId) external view returns(string memory svgPart, string memory tag) {
    INounsSeeder.Seed memory seed;
    (seed.background, seed.body, seed.accessory, seed.head, seed.glasses) = nounsToken.seeds(_assetId);
    tag = string(abi.encodePacked(providerKey, _assetId.toString()));
    svgPart = svgForSeed(seed, tag);
  }

  function getNounsTotalSuppy() external view returns(uint256) {
    return nounsToken.totalSupply();
  }

  function svgForSeed(INounsSeeder.Seed memory _seed, string memory _tag) public view returns(string memory svgPart) {
    string memory encodedSvg = descriptor.generateSVGImage(_seed);
    bytes memory svg = Base64.decode(encodedSvg);
    uint256 length = svg.length;
    uint256 start = 0;
    for (uint256 i=0; i < length; i++) {
      if (uint8(svg[i]) == 0x2F && uint8(svg[i+1]) == 0x3E) {  // "/>": looking for the end of <rect ../>
        start = i + 2;
        break;
      }
    }
    length -= start + 6; // "</svg>"

    // substring
    /*
    bytes memory ret = new bytes(length);
    for(uint i = 0; i < length; i++) {
        ret[i] = svg[i+start];
    }
    */

    bytes memory ret;
    assembly {
      ret := mload(0x40)
      mstore(ret, length)
      let retMemory := add(ret, 0x20)
      let svgMemory := add(add(svg, 0x20), start)
      for {let i := 0} lt(i, length) {i := add(i, 0x20)} {
        let data := mload(add(svgMemory, i))
        mstore(add(retMemory, i), data)
      }
      mstore(0x40, add(add(ret, 0x20), length))
    }

    svgPart = string(abi.encodePacked(
      '<g id="', _tag, '" transform="scale(3.2)" shape-rendering="crispEdges">\n',
      ret,
      '\n</g>\n'));
  }

  function totalSupply() external pure override returns(uint256) {
    return 0; // indicating "dynamically (but deterministically) generated from the given assetId)
  }

  function processPayout(uint256 _assetId) external override payable {
    address payable payableTo = payable(owner());
    payableTo.transfer(msg.value);
    emit Payout(providerKey, _assetId, payableTo, msg.value);
  }

  function generateTraits(uint256 _assetId) external pure override returns (string memory traits) {
    // nothing to return
  }
}