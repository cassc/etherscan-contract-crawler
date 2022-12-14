// SPDX-License-Identifier: MIT

/**
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import 'assetprovider.sol/IAssetProvider.sol';
import 'randomizer.sol/Randomizer.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '../packages/graphics/Path.sol';
import '../packages/graphics/SVG.sol';
import '../packages/graphics/Text.sol';
import '../packages/graphics/IFontProvider.sol';

contract PNounsPrivider is IAssetProviderEx, Ownable, IERC165 {
  using Strings for uint256;
  using Randomizer for Randomizer.Seed;
  using Vector for Vector.Struct;
  using Path for uint[];
  using SVG for SVG.Element;
  using TX for string;
  using Trigonometry for uint;

  IFontProvider public immutable font;
  IAssetProvider public immutable nounsProvider;

  constructor(IFontProvider _font, IAssetProvider _nounsProvider) {
    font = _font;
    nounsProvider = _nounsProvider;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IAssetProvider).interfaceId ||
      interfaceId == type(IAssetProviderEx).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  function getOwner() external view override returns (address) {
    return owner();
  }

  function getProviderInfo() external view override returns (ProviderInfo memory) {
    return ProviderInfo('pnouns', 'pNouns', this);
  }

  function totalSupply() external pure override returns (uint256) {
    return 0;
  }

  function processPayout(uint256 _assetId) external payable override {
    address payable payableTo = payable(owner());
    payableTo.transfer(msg.value);
    emit Payout('pnouns', _assetId, payableTo, msg.value);
  }

  function generateTraits(uint256 _assetId) external pure override returns (string memory traits) {
    // nothing to return
  }

  // Hack to deal with too many stack variables
  struct Stackframe {
    uint trait; // 0:small, 1:middle, 2:large
    uint degree;
    uint distance;
    uint radius;
    uint rotate;
    int x;
    int y;
  }

  function circles(uint _assetId, string[] memory idNouns) internal pure returns (SVG.Element memory) {
    string[4] memory colors = ['red', 'green', 'yellow', 'blue'];
    uint count = 10;
    SVG.Element[] memory elements = new SVG.Element[](count);
    Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);

    for (uint i = 0; i < count; i++) {
      Stackframe memory stack;
      stack.trait = (i + 1) / 4; // 3:4:3
      if (stack.trait == 0) {
        (seed, stack.distance) = seed.random(100);
        stack.distance += 380;
        (seed, stack.radius) = seed.random(40);
        stack.radius += 40;
        (seed, stack.rotate) = seed.random(360);
      } else if (stack.trait == 1) {
        (seed, stack.distance) = seed.random(100);
        stack.distance += 200;
        (seed, stack.radius) = seed.random(70);
        stack.radius += 70;
        (seed, stack.rotate) = seed.random(240);
        stack.rotate += 240;
      } else {
        (seed, stack.distance) = seed.random(180);
        (seed, stack.radius) = seed.random(70);
        stack.radius += 180;
        (seed, stack.rotate) = seed.random(120);
        stack.rotate += 300;
      }
      (seed, stack.degree) = seed.random(0x4000);
      stack.x = 512 + (stack.degree.cos() * int(stack.distance)) / Vector.ONE;
      stack.y = 512 + (stack.degree.sin() * int(stack.distance)) / Vector.ONE;
      elements[i] = SVG.group(
        [
          SVG.use(idNouns[i % idNouns.length]).transform(
            TX
              .translate(stack.x - int(stack.radius), stack.y - int(stack.radius))
              .scale1000((1000 * stack.radius) / 512)
              .rotate(string(abi.encodePacked(stack.rotate.toString(), ',512,512')))
          ),
          SVG.circle(stack.x, stack.y, int(stack.radius + stack.radius / 10)).fill(colors[i % 4]).opacity('0.333')
        ]
      );
    }
    return SVG.group(elements);
  }

  struct StackFrame2 {
    uint width;
    SVG.Element pnouns;
    string[] idNouns;
    SVG.Element[] svgNouns;
    string svg;
    string seriesText;
    SVG.Element series;
  }

  function generateSVGPart(uint256 _assetId) public view override returns (string memory svgPart, string memory tag) {
    StackFrame2 memory stack;
    tag = string(abi.encodePacked('circles', _assetId.toString()));
    stack.width = SVG.textWidth(font, 'pNouns');
    stack.pnouns = SVG.text(font, 'pNouns').fill('#224455').transform(TX.scale1000((1000 * 1024) / stack.width));

    if (_assetId < 10) {
      stack.seriesText = string(abi.encodePacked('000', _assetId.toString(), '/2000'));
    } else if (_assetId < 100) {
      stack.seriesText = string(abi.encodePacked('00', _assetId.toString(), '/2000'));
    } else if (_assetId < 1000) {
      stack.seriesText = string(abi.encodePacked('0', _assetId.toString(), '/2000'));
    } else {
      stack.seriesText = string(abi.encodePacked(_assetId.toString(), '/2000'));
    }
    stack.width = SVG.textWidth(font, stack.seriesText);
    stack.series = SVG.text(font, stack.seriesText).fill('#224455').transform(
      TX.translate(1024 - int(stack.width / 10), 1024 - 102).scale('0.1')
    );

    stack.idNouns = new string[](3);
    stack.svgNouns = new SVG.Element[](3);
    for (uint i = 0; i < stack.idNouns.length; i++) {
      (stack.svg, stack.idNouns[i]) = nounsProvider.generateSVGPart(i + _assetId);
      stack.svgNouns[i] = SVG.element(bytes(stack.svg));
    }

    svgPart = string(
      SVG
        .list(
          [
            SVG.list(stack.svgNouns),
            SVG
              .group(
                [
                  circles(_assetId, stack.idNouns).transform('translate(102,204) scale(0.8)'),
                  stack.pnouns,
                  stack.series
                ]
              )
              .id(tag)
          ]
        )
        .svg()
    );
  }

  function generateSVGDocument(uint256 _assetId) external view override returns (string memory document) {
    string memory svgPart;
    string memory tag;
    (svgPart, tag) = generateSVGPart(_assetId);
    document = SVG.document('0 0 1024 1024', bytes(svgPart), SVG.use(tag).svg());
  }
}