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
import { ISVGHelper } from './interfaces/ISVGHelper.sol';
import "trigonometry.sol/Trigonometry.sol";
import "randomizer.sol/Randomizer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import "hardhat/console.sol";

contract SplatterProvider is IAssetProviderEx, IERC165, Ownable {
  using Strings for uint;
  using Strings for uint256;
  using Randomizer for Randomizer.Seed;
  using Trigonometry for uint;

  struct Props {
    uint count; // number of control points
    uint length; // average length fo arm
    uint dot; // average size of dot
  }

  string constant providerKey = "splt";
  address public receiver;
  ISVGHelper svgHelper;

  constructor(ISVGHelper _svgHelper) {
    receiver = owner();
    svgHelper = _svgHelper;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IAssetProvider).interfaceId ||
      interfaceId == type(IAssetProviderEx).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  function getOwner() external override view returns (address) {
    return owner();
  }

  function getProviderInfo() external view override returns(ProviderInfo memory) {
    return ProviderInfo(providerKey, "Splatter", this);
  }

  function totalSupply() external pure override returns(uint256) {
    return 0; // indicating "dynamically (but deterministically) generated from the given assetId)
  }

  function processPayout(uint256 _assetId) external override payable {
    address payable payableTo = payable(receiver);
    payableTo.transfer(msg.value);
    emit Payout(providerKey, _assetId, payableTo, msg.value);
  }

  function setReceiver(address _receiver) onlyOwner external {
    receiver = _receiver;
  }

  // Work-around stack too deep issue
  struct StackFrame {
    int x;
    int y;
  }

  function setHelper(ISVGHelper _svgHelper) external onlyOwner {
    svgHelper = _svgHelper;
  }

  function generatePoints(Randomizer.Seed memory _seed, Props memory _props) pure internal returns(Randomizer.Seed memory, uint[] memory) {
    Randomizer.Seed memory seed = _seed;
    uint[] memory degrees = new uint[](_props.count);
    uint total;
    for (uint i = 0; i < _props.count; i++) {
      uint degree;
      (seed, degree) = seed.randomize(100, 90);
      degrees[i] = total;
      total += degree;
    }

    uint r0 = 220;
    uint r1 = r0;
    uint[] memory points = new uint[](_props.count  + _props.count /3 * 5);
    StackFrame memory stack;
    uint j = 0;
    for (uint i = 0; i < _props.count; i++) {
      {
        uint angle = degrees[i] * 0x4000 / total + 0x4000;
        if (i % 3 == 0) {
          uint extra;
          (seed, extra) = seed.randomize(_props.length, 100);
          uint arc;
          (seed, arc) = seed.randomize(_props.dot, 50);
          uint arc0 = arc / 3;

          stack.x = int(512 + (angle - arc0).cos() * int(r1) / 0x8000);
          stack.y = int(512 + (angle - arc0).sin() * int(r1) / 0x8000);
          points[j] = uint(uint16(int16(stack.x))) + (uint(uint16(int16(stack.y))) << 16) + (1024 << 32);
          j++;
          stack.x = int(512 + (angle - arc0).cos() * int(r1 + extra) / 0x8000);
          stack.y = int(512 + (angle - arc0).sin() * int(r1 + extra) / 0x8000);
          points[j] = uint(uint16(int16(stack.x))) + (uint(uint16(int16(stack.y))) << 16) + (566 << 32);
          j++;
          stack.x = int(512 + (angle - arc).cos() * int(r1 + extra * (150 + arc) / 150) / 0x8000);
          stack.y = int(512 + (angle - arc).sin() * int(r1 + extra * (150 + arc) / 150)  / 0x8000);
          points[j] = uint(uint16(int16(stack.x))) + (uint(uint16(int16(stack.y))) << 16) + (566 << 32);
          j++;
          stack.x = int(512 + (angle + arc).cos() * int(r1 + extra * (150 + arc) / 150)  / 0x8000);
          stack.y = int(512 + (angle + arc).sin() * int(r1 + extra * (150 + arc) / 150)  / 0x8000);
          points[j] = uint(uint16(int16(stack.x))) + (uint(uint16(int16(stack.y))) << 16) + (566 << 32);
          j++;
          stack.x = int(512 + (angle + arc0).cos() * int(r1 + extra) / 0x8000);
          stack.y = int(512 + (angle + arc0).sin() * int(r1 + extra) / 0x8000);
          points[j] = uint(uint16(int16(stack.x))) + (uint(uint16(int16(stack.y))) << 16) + (566 << 32);
          j++;
          stack.x = int(512 + (angle + arc0).cos() * int(r1) / 0x8000);
          stack.y = int(512 + (angle + arc0).sin() * int(r1) / 0x8000);
          points[j] = uint(uint16(int16(stack.x))) + (uint(uint16(int16(stack.y))) << 16) + (1024 << 32);
          j++;
        } else {
          stack.x = int(512 + angle.cos() * int(r1) / 0x8000);
          stack.y = int(512 + angle.sin() * int(r1) / 0x8000);
          points[j] = uint(uint16(int16(stack.x))) + (uint(uint16(int16(stack.y))) << 16) + (566 << 32);
          j++;
        }
      }
      {
        uint r2;
        (seed, r2) = seed.randomize(r1, 20);
        r1 = (r2 * 2 + r0) / 3;
      }
    }
    return (seed, points);
  }

  function generatePath(Randomizer.Seed memory _seed, Props memory _props) public view returns(Randomizer.Seed memory seed, bytes memory svgPart) {
    uint[] memory points;
    (seed, points) = generatePoints(_seed, _props);
    svgPart = svgHelper.pathFromPoints(points);
  }

  function generateProps(Randomizer.Seed memory _seed) public pure returns(Randomizer.Seed memory seed, Props memory props) {
    seed = _seed;
    props = Props(30, 40, 140);
    (seed, props.count) = seed.randomize(props.count, 50); // +/- 50%
    (seed, props.length) = seed.randomize(props.length, 50); // +/- 50%
    (seed, props.dot) = seed.randomize(props.dot + 1000 / props.count, 50);
    props.count = props.count / 3 * 3; // always multiple of 3
  }

  function generateSVGPart(uint256 _assetId) external view override returns(string memory svgPart, string memory tag) {
    Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);
    Props memory props;
    (seed, props) = generateProps(seed);

    bytes memory path;
    (,path) = generatePath(seed, props);

    tag = string(abi.encodePacked(providerKey, _assetId.toString()));
    svgPart = string(abi.encodePacked(
      '<g id="', tag, '">\n'
      '<path d="', path, '"/>\n'
      '</g>\n'
    ));
  }

  /**
   * An optional method, which allows MultplexProvider to create a new set of assets.
   */
  function generateRandomProps(Randomizer.Seed memory _seed) external override pure returns(Randomizer.Seed memory seed, uint256 prop) {
    Props memory props;
    (seed, props) = generateProps(_seed);
    prop = props.count + props.length * 0x10000 + props.dot * 0x100000000;
  }

  /**
   * An optional method, which allows MultplexProvider to create a new set of assets.
   */
  function generateSVGPartWithProps(Randomizer.Seed memory _seed, uint256 _prop, string memory _tag) external override view 
    returns(Randomizer.Seed memory seed, string memory svgPart) {
    Props memory props;
    props.count = _prop & 0xffff;
    props.length = (_prop / 0x10000) & 0xffff;
    props.dot = (_prop / 0x100000000) & 0xffff;
    bytes memory path;
    (seed, path) = generatePath(_seed, props);
    svgPart = string(abi.encodePacked(
      '<g id="', _tag, '">\n'
      '<path d="', path, '"/>\n'
      '</g>\n'
    ));
  }

  function generateTraits(uint256 _assetId) external pure override returns (string memory traits) {
    // nothing to return
  }
}