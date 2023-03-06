// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { Strings} from "openzeppelin/utils/Strings.sol";
import { DynamicBuffer } from 'ethier/utils/DynamicBuffer.sol';
import { Base64 } from "solady/utils/Base64.sol";
import "forge-std/console.sol";

contract ASCIIChecksRender {
    
    string[20] signs = ["", "#", "=", "+", "(", ")", "{", "}", ",", '_', '"', '/', '|', '\\', '$', '-', '*', ":", "o", "O"];
    //bytes3[2] colors = [bytes3(0x523452), 0xef492dc]; 
    string[13] colors = ["#23b5fc", "#3fd241", "#9a2ef1", "#f26c9b", "#fae866", "#a0eec0", "#d21a20", "#a5c9ec", "#96e146", "#d93595", "#001fcc", "#ffc814", "#999999" ];
    //uint8[5] sizeLookup = [20,16, 12, 8, 6];
    using DynamicBuffer for bytes;

    function tokenURI(uint256 tokenId, uint16[] memory _signs, uint8[] memory _colors) external view returns (string memory) {
      string[] memory _signSymbols = getSymbols(_signs);
      //'data:application/json,', 
      string memory _outString = string.concat('{', '"name" : "ASCII Checks #' , Strings.toString(tokenId), '", ',
            '"description" : "Burn and Build"');
      _outString = string.concat(_outString, ',"attributes":[');
      for(uint8 i; i < _signs.length; i++) {
          if(i > 0) _outString = string.concat(_outString,',');
            _outString = string.concat(
            _outString,
            '{"trait_type":"Sign","value":"', _signSymbols[i],'"},{"trait_type":"Color","value":"',colors[_colors[i]],'"}');
      }
      _outString = string.concat(_outString,'],"image": "data:image/svg+xml;base64,', Base64.encode(bytes(tokenSVG(_signs, _colors))),'"');
      _outString = string.concat(_outString,'}');
      return string.concat("data:application/json;base64,", Base64.encode(bytes(_outString)));
   }

   function getSymbols(uint16[] memory _signs) internal view returns (string[] memory out) {
    out = new string[](_signs.length);
    for(uint8 i; i < _signs.length; i++) {
      out[i] = string.concat(signs[(_signs[i])/20], signs[_signs[i]%20]);
    }
   }

      function tokenSVG(uint16[] memory _signs, uint8[] memory _colors)
        public
        view
        returns (string memory)
    {
        
        //ICrypToadzBuilder.GIF memory data = builder.getImage(meta);
        bytes memory buffer = DynamicBuffer.allocate(2**22);
        uint256 xOffset;
        uint256 yOffset;

        string[] memory _signSymbols = getSymbols(_signs);

        buffer.appendSafe('<svg width="680" height="720" viewBox="0 0 680 720" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#121212"/>');
        buffer.appendSafe('<defs><text id="Sign" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">');
        for(uint8 i; i < _signs.length; i++) {
          if(_signs[i] == 0) {
            yOffset += 20;
            xOffset = 0;
            continue;
          }
          buffer.appendSafe(abi.encodePacked('<tspan dy="',Strings.toString(yOffset),'" dx="',Strings.toString(xOffset),'" fill="', colors[_colors[i]],'">',_signSymbols[i] ,'</tspan>'));
        }
        buffer.appendSafe('</text></defs>');
        for(uint256 i; i < 10; ++i) {
          for(uint256 j; j < 8; ++j) {
            buffer.appendSafe(abi.encodePacked('<use x="',Strings.toString(130+j*60),'" y="',Strings.toString(95+i*60),'" href="#Sign"/>'));
          }
        }
        buffer.appendSafe('</svg>');
        //return string.concat("data:image/svg+xml;base64,", Base64.encode(buffer));
        return string(buffer);
    }

}