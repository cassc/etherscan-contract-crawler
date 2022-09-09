// SPDX-License-Identifier: MIT
// coded by @eddietree

pragma solidity ^0.8.0;

import 'base64-sol/base64.sol';
import "./IEthKunRenderer.sol";
import "./EthKunData.sol";

contract EthKunRenderer is IEthKunRenderer, EthKunData {

  string[] public bgPaletteColors = [
     'ffffff', 'fdf8db', 'fdeddb', 'fee5e0', 'feddec', 'feddf5', 'f7defe', 'ecddfe', 'dfdbfe', 'e1edfe', 'e4fafe', 'dffef3', 'dffee1', '122026'
  ];

  string[] public bodyColors = [
    '80b0bb','56b7e9','e1624a','85ae36',
    'e7b509','f6b099','85ae36','de953a',
    '56b7e9','dd5bca','80b0bb','56b7e9',
    'e1624a','85ae36','debb45', 'f6b099'
  ];
  
  struct CharacterData {
    uint background;

    uint body;
    uint eyes;
    uint mouth;
  }

  function getSVG(uint256 seed, uint256 level) external view returns (string memory) {
    return _getSVG(seed, level);
  }

  function _getSVG(uint256 seed, uint256 level) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    // clamp to max
    uint256 levelIndex = level;
    if (levelIndex > levels.length) 
    {
      levelIndex = levels.length;
    }
    levelIndex = levelIndex-1;// map from [1,32]->[0,31]

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" shape-rendering="crispEdges" width="512" height="512">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      //_renderRects(levels[levelIndex], fullPalettes),
      _renderRectsSingleColor(levels[levelIndex], fullPalettes, bodyColors[data.body]),
      //_renderRectsSingleColor(levels[seed % (levels.length)], fullPalettes, bodyColors[data.body]),
      _renderRects(bodies[data.body], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getUnrevealedSVG(uint256 seed) external view returns (string memory) {
    return _getUnrevealedSVG(seed);
  }

  function _getUnrevealedSVG(uint256) internal view returns (string memory) {
    //CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" shape-rendering="crispEdges" width="512" height="512">'
      //'<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      '<rect width="100%" height="100%" fill="#122026"/>',
      _renderRects(misc[0], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getTraitsMetadata(uint256 seed) external view returns (string memory) {
    return _getTraitsMetadata(seed);
  }

  function _getTraitsMetadata(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    // just for backgrounds
    string[15] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14'
    ];

    string memory metadata = string(abi.encodePacked(
      '{"trait_type":"Background", "value":"', lookup[data.background+1], '"},',
      '{"trait_type":"Body", "value":"', bodies_traits[data.body], '"},',
      '{"trait_type":"Eyes", "value":"', eyes_traits[data.eyes], '"},',
      '{"trait_type":"Mouth", "value":"', mouths_traits[data.mouth], '"},'
    ));

    return metadata;
  }

  function _renderRects(bytes memory data, string[] memory palette) private pure returns (string memory) {
    string[33] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
      '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
      '30', '31', '32'
    ];

    string memory rects;
    uint256 drawIndex = 0;

    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (32px)
      uint8 colorIndex = uint8(data[i+1]);

      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 32);
        uint8 y = uint8(drawIndex / 32);
        string memory color = palette[colorIndex];

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', color, '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _renderRectsSingleColor(bytes memory data, string[] memory palette, string memory color) private pure returns (string memory) {
    string[33] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
      '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
      '30', '31', '32'
    ];

    string memory rects;
    uint256 drawIndex = 0;

    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (32px)
      uint8 colorIndex = uint8(data[i+1]);

      if (colorIndex == 0) { // transparent
      }
      else if (colorIndex==1) { // black - replace color

        uint8 x = uint8(drawIndex % 32);
        uint8 y = uint8(drawIndex / 32);

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', color, '"/>'));
      }
      else { // any othe rcolor
        uint8 x = uint8(drawIndex % 32);
        uint8 y = uint8(drawIndex / 32);

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', palette[colorIndex], '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _generateCharacterData(uint256 seed) private view returns (CharacterData memory) {
    return CharacterData({
      background: seed % bgPaletteColors.length,
      
      body: bodies_indices[(seed/2) % bodies_indices.length],
      eyes: eyes_indices[(seed/3) % eyes_indices.length],
      mouth: mouths_indices[(seed/4) % mouths_indices.length]
    });
  }
}