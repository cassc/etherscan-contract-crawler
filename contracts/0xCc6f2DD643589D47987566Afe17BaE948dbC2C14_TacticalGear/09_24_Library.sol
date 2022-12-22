// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import './interfaces/ITacticalGear.sol';
import './interfaces/ILibrary.sol';

library Library {
  function calculateFontSize(string memory text) internal pure returns (string memory) {
    uint256 maxSize = 33;
    uint256 baseSize = 4;
    uint256 size = baseSize;
    uint256 length = bytes(text).length;

    if (length > maxSize) {
      size = 3;
    }

    return string(abi.encodePacked(Strings.toString(size), 'px'));
  }

  function random(string memory name, uint256 seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(name, seed)));
  }

  function isEqualStrings(string memory stringA, string memory stringB) internal pure returns (bool) {
    return keccak256(abi.encodePacked(stringA)) == keccak256(abi.encodePacked(stringB));
  }

  function getMetadata(
    ITacticalGear.Item memory item,
    string memory suffix,
    string memory prefix,
    bool isForged,
    bool hasR0N1,
    string memory image
  ) internal pure returns (string memory) {
    string memory name = item.name;
    string memory category = item.category;

    // prettier-ignore
    string memory metadata = string(
      abi.encodePacked(
        '{',
          isForged ?
            string(abi.encodePacked('"name": "', prefix, ' ', name, ' ', suffix, '",')) :
            string(abi.encodePacked('"name": "', name, ' ', suffix, '",')),
          '"description": "It got empty in the vents after 0BER1N had gone missing. The need for weapons and armor is now greater than it ever was.",',
          '"attributes": [',
            abi.encodePacked(
              '{"trait_type": "Name", "value": "', name, '"},',
              isForged ? string(abi.encodePacked('{"trait_type": "Prefix", "value": "', prefix, '"},')) : '',
              '{"trait_type": "Suffix", "value": "', suffix, '"},',
              '{"trait_type": "Category", "value": "', category, '"}',
              isForged && hasR0N1 ? string(abi.encodePacked(',{"trait_type": "Extra", "value": "', hasR0N1 ? 'R0N1' : 'None', '"}')) : ''
            ),
          '],',
          '"image": "', image, '"'
        '}'
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(metadata))));
  }

  function getImage(ILibrary.ImageInput memory data) internal pure returns (string memory) {
    bytes memory svg = bytes(
      abi.encodePacked(
        "<svg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:xhtml='http://www.w3.org/1999/xhtml' width='640' height='640' preserveAspectRatio='xMidYMid meet' viewBox='0 0 64 64' style='stroke-width:0; background-color:hsl(0,0%,0%); margin: auto;height: -webkit-fill-available'>",
        "<style type='text/css'>.pixelated { image-rendering: pixelated; }</style>",
        abi.encodePacked(
          data.hasR0N1 ? Library.foreignImage('0', '0', '64', '64', data.r0n1Graphic) : '',
          Library.foreignImage('0', '0', '64', '64', data.itemGraphic),
          data.isForged ? Library.foreignImage('0', '0', '64', '64', data.prefixGraphic) : ''
        ),
        '</svg>'
      )
    );

    return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg)));
  }

  function getCardImage(ILibrary.CardImageInput memory data) internal pure returns (string memory) {
    // prettier-ignore
    bytes memory svg = bytes(
      abi.encodePacked(
        "<svg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:xhtml='http://www.w3.org/1999/xhtml' width='760' height='1140' preserveAspectRatio='xMidYMid meet' viewBox='0 0 76 114' style='stroke-width:0; background-color:hsl(0,0%,0%); margin: auto;height: -webkit-fill-available'>",
        abi.encodePacked(
          "<style type='text/css'>",
            "@font-face { font-family: GearFont; src: url('", data.font, "'); }",
            ".pixelated { image-rendering: pixelated; }",
            ".name { font-family: GearFont; font-size: ", Library.calculateFontSize(string(abi.encodePacked(data.name, ' ', data.suffix))), "; text-transform: uppercase; fill: black; }",
          "</style>"
        ),
        "<rect width='100%' height='100%' x='0' y='0' fill='#887e88' />",
        abi.encodePacked(
          data.hasR0N1 ? Library.foreignImage('6', '18', '64', '64', data.r0n1Graphic) : '',
          Library.foreignImage('0', '0', '76', '114', data.cardGraphic),
          Library.foreignImage('6', '18', '64', '64', data.itemGraphic),
          Library.foreignImage('30', '0', '16', '12', data.suffixGraphic),
          data.isForged ? Library.foreignImage('6', '18', '64', '64', data.prefixGraphic) : ''
        ),
        data.isForged
          ? string(abi.encodePacked(
            "<text x='50%' y='103.50' text-anchor='middle' dominant-baseline='bottom' class='name'>", data.prefix, "</text>",
            "<text x='50%' y='106.75' text-anchor='middle' dominant-baseline='top' class='name'>", abi.encodePacked(data.name, " ", data.suffix), "</text>"
          ))
          : string(
            abi.encodePacked(
              "<text x='50%' y='104.50' text-anchor='middle' dominant-baseline='middle' class='name'>",
              abi.encodePacked(data.name, ' ', data.suffix),
              '</text>'
            )
          ),
        '</svg>'
      )
    );

    return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg)));
  }

  function foreignImage(
    string memory x,
    string memory y,
    string memory width,
    string memory height,
    string memory img
  ) internal pure returns (string memory) {
    // prettier-ignore
    return
      string(
        (
          abi.encodePacked(
            "<foreignObject x='", x, "' y='", y, "' width='", width, "' height='", height, "'>",
              "<xhtml:img class='pixelated' width='100%' height='100%' src='", img, "'/>",
            '</foreignObject>'
          )
        )
      );
  }
}