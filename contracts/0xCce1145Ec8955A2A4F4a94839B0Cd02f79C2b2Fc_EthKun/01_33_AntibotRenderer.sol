// SPDX-License-Identifier: MIT
// referenced from original Aribibots render code.

pragma solidity ^0.8.0;

import 'base64-sol/base64.sol';

contract BotRenderer {

  mapping(uint256 => uint256) public seeds; // will be copied from OG Arbibots contract
  mapping(uint256 => bool) public flipped;

  string[][] public palettes = [
    ['#b5eaea', '#edf6e5', '#f38ba0'],
    ['#b5c7ea', '#e5f6e8', '#f3bb8b'],
    ['#eab6b5', '#eee5f6', '#8bf3df'],
    ['#c3eab5', '#f6e9e5', '#c18bf3'],
    ['#eab5d9', '#e5e8f6', '#8bf396']
  ];

  bytes[] public bodies = [
    bytes(hex'ff00ba0001010404010111000101060301010f000101080301010d000101090301010d000101090301010d00010109030101'),
    bytes(hex'ff00ba0001010404010111000101060301010f000101080301010d000101090301010d000101090301010d00010109030101'),
    bytes(hex'ff00b90001010504010111000101050301011100010105030101110001010503010111000101050301011100010105030101'),
    bytes(hex'ff00ba000101030401011200010105030101100001010104010103030101010401010e00010103040301030401010c0001010b0401010a0001010d040101'),
    bytes(hex'ff00b9000101050301010f0002010104010103030101010402010c00010104040301040401010a0001010d040101090001010d040101090001010d040101'),
    bytes(hex'ff00ba00010103030101120001010104010101030101010401011000010103040101030401010f000101070401010f000101070401010f00010107040101'),
    bytes(hex'ff00ba0001010104010101030101010401011000010103040101020401010f00010104040101030401010e00010104040101040401010d00010104040101040401010d0001010404010104040101')
  ];

  bytes[] public heads = [
    bytes(hex'96000c010b0001010c030101090001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e03010109000e01'),
    bytes(hex'97000a010d0001010a0301010b0001010c030101090001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e030101090001010c0301010b0001010a0301010d000a01'),
    bytes(hex'9400100107000101100401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e0301040101060001011004010107001001'),
    bytes(hex'96000c010b0001010c030101090001010e030101070001011003010105000101120301010400010112030101040001011203010104000101120301010500010110030101070001010d030201090001010b0301010c000b01'),
    bytes(hex'9400100107000101100301010600010110030101060001011003010106000101100301010600010110030101070001010e030101080001010e030101090001010c0301010a0001010c0301010b0001010a0301010d000a01')
  ];

  bytes[] public eyes = [
    bytes(hex'ff0010000201070002010d0001010104070001010104ff00'),
    bytes(hex'ff001000030105000301ff00'),
    bytes(hex'f8000101070001010e000101010001010500010101000101ff00'),
    bytes(hex'df000301050003010d000301050003010e00010107000101ff00'),
    bytes(hex'ff0011000101070001010f00010107000101ff00'),
    bytes(hex'ff00100001010100010105000101010001010e00010107000101ff00')
  ];

  bytes[] public mouths = [
    bytes(hex'ff004300010101000101010001011400010101000101'),
    bytes(hex'ff00450001011600010101000101'),
    bytes(hex'ff005c000401'),
    bytes(hex'ff00440001010200010115000201'),
    bytes(hex'ff0044000401140001010204010115000201')
  ];

  bytes[] public headgears = [
    bytes(hex'37000101080001010d0001010100010106000101010001010e000101060001011000010106000101ff00'),
    bytes(hex'240001011600010101000101150001011700010117000101ff00'),
    bytes(hex'0c000201150001010200010114000101010001010104010113000101020001011400010117000101ff00'),
    bytes(hex'68000101060001010f000101010301010400010101030101ff00'),
    bytes(hex'50000101060001010f0001010103010104000101010301010e000101020301010200010102030101ff00')
  ];

  struct BotData {
    uint palette;
    uint body;
    uint head;
    uint eyes;
    uint mouth;
    uint headgear;
  }

  function _getSVG(uint256 tokenId) internal view returns (string memory) {
    BotData memory data = _generateBotData(tokenId);
    string[] memory palette = palettes[data.palette];

    bool flip = flipped[tokenId];

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="256" height="256">'
      '<rect width="100%" height="100%" fill="', palette[0], '" />',
      _renderRectsSingleColor(bodies[data.body], '#000000', flip),
      _renderRectsSingleColor(heads[data.head], '#000000', flip),
      _renderRects(eyes[data.eyes], palette, '#ffffff', flip),
      _renderRects(mouths[data.mouth], palette, '#ffffff', flip),
      _renderRects(headgears[data.headgear], palette, '#000000', flip),
      '</svg>'
    ));

    return image;
  }

  function _render(uint256 tokenId) internal view returns (string memory) {
   
    string memory image = _getSVG(tokenId);

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(
        bytes(
          abi.encodePacked('{"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}')
        )
      )
    ));
  }

  function _renderRectsSingleColor(bytes memory data, string memory color, bool flip) private pure returns (string memory) {
    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory rects;
    uint256 drawIndex = 0;
    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (24px)
      uint8 colorIndex = uint8(data[i+1]);
      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 24);
        x = 24-x-runLength; // mirror horizontally
        uint8 y = uint8(drawIndex / 24);

        if (flip) // mirror vertically
            y = 23-y;

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="', color, '" />'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _renderRects(bytes memory data, string[] memory palette, string memory defaultColor, bool flip) private pure returns (string memory) {
    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory rects;
    uint256 drawIndex = 0;
    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (24px)
      uint8 colorIndex = uint8(data[i+1]);
      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 24);
        x = 24-x-runLength; // mirror horizontally
        uint8 y = uint8(drawIndex / 24);
        
        if (flip) // mirror vertically
            y = 23-y;

        string memory color = defaultColor;
        if (colorIndex > 1) {
          color = palette[colorIndex-2];
        }
        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="', color, '" />'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _generateBotData(uint256 tokenId) private view returns (BotData memory) {
    uint256 seed = seeds[tokenId];

    return BotData({
      palette: seed % palettes.length,
      body: (seed/2) % bodies.length,
      head: (seed/3) % heads.length,
      eyes: (seed/4) % eyes.length,
      mouth: (seed/5) % mouths.length,
      headgear: (seed/6) % headgears.length
    });
  }
}