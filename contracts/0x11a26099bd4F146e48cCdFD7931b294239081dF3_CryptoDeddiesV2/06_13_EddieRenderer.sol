// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'base64-sol/base64.sol';

import "./EddieData.sol";

contract EddieRenderer is EddieData {

  string[] public bgPaletteColors = [
    'b5eaea', 'b5c7ea', 'eab6b5', 'c3eab5', 'eab5d9',
    'fafc51', '3a89ff', '5eff8f', 'ff6efa', 'a1a1a1'
  ];
  
  struct CharacterData {
    uint background;

    uint body;
    uint head;
    uint eyes;
    uint mouth;
    uint hair;
  }

  function getSVG(uint256 seed) external view returns (string memory) {
    return _getSVG(seed);
  }

  function _getSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      _renderRects(heads[data.head], fullPalettes),
      _renderRects(bodies[data.body], fullPalettes),
      _renderRects(hair[data.hair], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getGhostSVG(uint256 seed) external view returns (string memory) {
    return _getGhostSVG(seed);
  }

  function _getGhostSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#3b89ff"/>',
      //_renderRects(bodies[data.body], fullPalettes),
      //_renderRects(heads[data.head], fullPalettes),
      _renderRects(misc[0], fullPalettes), // ghost body
      _renderRects(hair[data.hair], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getUnrevealedSVG(uint256 seed) external view returns (string memory) {
    return _getUnrevealedSVG(seed);
  }

  function _getUnrevealedSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      _renderRects(misc[1], fullPalettes), // ghost body
      '</svg>'
    ));

    return image;
  }

  function getTraitsMetadata(uint256 seed) external view returns (string memory) {
    return _getTraitsMetadata(seed);
  }

  function _getTraitsMetadata(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory metadata = string(abi.encodePacked(
      '{"trait_type":"Background", "value":"', lookup[data.background+1], '"},',
      '{"trait_type":"Outfit", "value":"', bodies_traits[data.body], '"},',
      '{"trait_type":"Class", "value":"', heads_traits[data.head], '"},',
      '{"trait_type":"Eyes", "value":"', eyes_traits[data.eyes], '"},',
      '{"trait_type":"Mouth", "value":"', mouths_traits[data.mouth], '"},',
      '{"trait_type":"Head", "value":"', hair_traits[data.hair], '"},'
    ));

    return metadata;
  }

  function _renderRects(bytes memory data, string[] memory palette) private pure returns (string memory) {
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
        uint8 y = uint8(drawIndex / 24);
        string memory color = palette[colorIndex];

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', color, '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _generateCharacterData(uint256 seed) private view returns (CharacterData memory) {
    return CharacterData({
      background: seed % bgPaletteColors.length,
      
      body: bodies_indices[(seed/2) % bodies_indices.length],
      head: heads_indices[(seed/3) % heads_indices.length],
      eyes: eyes_indices[(seed/4) % eyes_indices.length],
      mouth: mouths_indices[(seed/5) % mouths_indices.length],
      hair: hair_indices[(seed/6) % hair_indices.length]
    });
  }
}