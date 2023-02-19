// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Base64.sol";

interface ITerraformsCharacters {
    function font(uint) external view returns (string memory);
}

struct TokenData {
    uint tokenId;
    uint level;
    uint xCoordinate;
    uint yCoordinate;
    int elevation;
    int structureSpaceX;
    int structureSpaceY;
    int structureSpaceZ;
    string zoneName;
    string[10] zoneColors;
    string[9] characterSet;
}

interface ITerraformsData {
  function tokenSupplementalData(uint tokenId) 
    external 
    view
    returns (TokenData memory); 
}

contract TerraflowsSVG {

    function tokenSVG(uint256 _tokenId, bool encoded) public view returns (string memory) {
        string memory svg = string.concat(
                '<svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" version="2.0" encoding="utf-8" viewBox="0 0 350 350" preserveAspectRatio="xMidYMid">',
                getSVGStyle(_tokenId),
                '<rect width="350" height="350" class="r"/>',
                '<rect width="290" height="44" x="50%" y="50%" transform="translate(-145,-22)" class="r" rx="8"/>'
                '<text  x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" textLength="75%" font-size="24" font-family="MathcastlesRemix-Regular">'
                '<tspan class="a">+</tspan>'
                '<tspan class="b">',unicode'㆔','</tspan>'
                '<tspan class="c">',unicode'╔','</tspan>'
                '<tspan class="d">',unicode'╔','</tspan>'
                '<tspan class="e">',unicode'⍝','</tspan>'
                '<tspan class="f">',unicode'༼','</tspan>'
                '<tspan class="g">',unicode'㇄','</tspan>'
                '<tspan class="h">',unicode'🟣','</tspan>'
                '<tspan class="i">',unicode'♛','</tspan>'
                '<tspan class="a">',unicode'▚','</tspan>'
                '</text></svg>'
            );
        if (!encoded) {
            return svg;
        }
        return string.concat(
        'data:image/svg+xml;base64,',
        Base64.encode(abi.encodePacked(svg))
        );
    }

    function getSVGStyle(uint256 _tokenId) internal view returns (string memory) {
      string[10] memory zoneColors = ITerraformsData(0x4E1f41613c9084FdB9E34E11fAE9412427480e56).tokenSupplementalData(_tokenId).zoneColors;
      string[10] memory classes = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];

      string[10] memory buf;
      for (uint i; i < 9; i ++){
          buf[i] = string.concat('.', classes[i], '{fill:', zoneColors[i],';background-color:', zoneColors[i],';}');
      }
      buf[9] = string(string.concat('.r{fill:', zoneColors[9],';background-color:', zoneColors[9],';}')
      );
      return string.concat(
                "<style>@font-face {font-family:'MathcastlesRemix-Regular';font-display:block;src:url(data:application/font-woff2;charset=utf-8;base64,",
                ITerraformsCharacters(0xC9e417B7e67E387026161E50875D512f29630D7B).font(1),
                ") format('woff');}",
                buf[0],
                buf[1],
                buf[2],
                buf[3],
                buf[4],
                buf[5],
                buf[6],
                buf[7],
                buf[8],
                buf[9],
                "</style>"
            );
    }
}