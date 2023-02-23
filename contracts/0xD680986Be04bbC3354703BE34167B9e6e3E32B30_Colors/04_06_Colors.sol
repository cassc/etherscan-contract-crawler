// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* 

░█████╗░░█████╗░██╗░░░░░░█████╗░██████╗░░██████╗  ░█████╗░███╗░░██╗  ░█████╗░██╗░░██╗░█████╗░██╗███╗░░██╗
██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██╔════╝  ██╔══██╗████╗░██║  ██╔══██╗██║░░██║██╔══██╗██║████╗░██║
██║░░╚═╝██║░░██║██║░░░░░██║░░██║██████╔╝╚█████╗░  ██║░░██║██╔██╗██║  ██║░░╚═╝███████║███████║██║██╔██╗██║
██║░░██╗██║░░██║██║░░░░░██║░░██║██╔══██╗░╚═══██╗  ██║░░██║██║╚████║  ██║░░██╗██╔══██║██╔══██║██║██║╚████║
╚█████╔╝╚█████╔╝███████╗╚█████╔╝██║░░██║██████╔╝  ╚█████╔╝██║░╚███║  ╚█████╔╝██║░░██║██║░░██║██║██║░╚███║
░╚════╝░░╚════╝░╚══════╝░╚════╝░╚═╝░░╚═╝╚═════╝░  ░╚════╝░╚═╝░░╚══╝  ░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝

░░░░░░  ███╗░░██╗░█████╗░  ██╗██████╗░███████╗░██████╗  ███╗░░██╗░█████╗░  ██████╗░░██████╗
░░░░░░  ████╗░██║██╔══██╗  ██║██╔══██╗██╔════╝██╔════╝  ████╗░██║██╔══██╗  ██╔══██╗██╔════╝
█████╗  ██╔██╗██║██║░░██║  ██║██████╔╝█████╗░░╚█████╗░  ██╔██╗██║██║░░██║  ██████╦╝╚█████╗░
╚════╝  ██║╚████║██║░░██║  ██║██╔═══╝░██╔══╝░░░╚═══██╗  ██║╚████║██║░░██║  ██╔══██╗░╚═══██╗
░░░░░░  ██║░╚███║╚█████╔╝  ██║██║░░░░░██║░░░░░██████╔╝  ██║░╚███║╚█████╔╝  ██████╦╝██████╔╝
░░░░░░  ╚═╝░░╚══╝░╚════╝░  ╚═╝╚═╝░░░░░╚═╝░░░░░╚═════╝░█  ╚═╝░░╚══╝░╚════╝░  ╚═════╝░╚═════╝░

         :         . : 
         .       *
                      (
                        )     (
                 ___...(-------)-....___
             .-""       )    (          ""-.
       .-'``'|-._             )         _.-|
      /  .--.|   `""---...........---""`   |
     /  /    |                                       |
     |  |    |                                        |
      \  \   |       Colors On Chain      |
       `\ `\ |                                       |
         `\ `|         Exclusively            |
         _/ /\        Generated and        /
        (__/  \      Stored On Chain      /
     _..---""` \                         /`""---.._
  .-'           \                       /                  '-.
 :               `-.__             __.-'                   :
 :                  ) ""---...---"" (                 :
  '._               `"--...___...--"`              _.'
    \""--..__                              __..--""/
     '._     """----.....______.....----"""     _.'
        `""--..,,_____            _____,,..--""`
                      `"""----"""`

*/

contract Colors is ERC721A, Ownable {
  bool public publicMintLive;
  mapping(string => uint256) public hexToDecimal;
  mapping(uint256 => string) public decimalToHex;

  string[] private hexes = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F"
  ];
  uint256[] private decimals = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15
  ];

  constructor() ERC721A("Colors", "COLORS") {
    for (uint i = 0; i < 16; i++) {
      hexToDecimal[hexes[i]] = decimals[i];
      decimalToHex[decimals[i]] = hexes[i];
    }
  }

  function flipPublicMintLive() external onlyOwner {
    publicMintLive = !publicMintLive;
  }

  function mint(address minter) external onlyOwner {
    require(publicMintLive, "Public mint not live");
    _safeMint(minter, 1);
  }

  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory) {
    string[5] memory parts;
    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">';
    parts[1] = '<rect width="100%" height="100%" fill="#';
    parts[2] = generateColor(tokenId);
    parts[3] = '" />';
    parts[4] = "</svg>";

    string memory output = string(
      abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Color #',
            toString(tokenId),
            '", "description": "No Ramp Colors are randomized hex colors generated and stored on chain. All functionality is intentionally omitted for others to interpret. Feel free to use Colors in any way you want.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '", "attributes": [{"trait_type": "Hex", "value": "#',
            generateColor(tokenId),
            '"}]}'
          )
        )
      )
    );
    output = string(abi.encodePacked("data:application/json;base64,", json));

    return output;
  }

  function getAHex(
    uint256 tokenId,
    string memory position,
    string[] memory hexArray
  ) internal pure returns (string memory) {
    uint256 rand = random(
      string(abi.encodePacked(position, toString(tokenId)))
    );
    string memory output = hexArray[rand % hexArray.length];
    output = string(abi.encodePacked(output));
    return output;
  }

  function generateColor(uint256 tokenId) public view returns (string memory) {
    string[6] memory parts;
    parts[0] = getAHex(tokenId, "0", hexes);
    parts[1] = getAHex(tokenId, "1", hexes);
    parts[2] = getAHex(tokenId, "2", hexes);
    parts[3] = getAHex(tokenId, "3", hexes);
    parts[4] = getAHex(tokenId, "4", hexes);
    parts[5] = getAHex(tokenId, "5", hexes);
    string memory output = string(
      abi.encodePacked(
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5]
      )
    );
    return output;
  }

  function buildHexString(
    uint256 red,
    uint256 green,
    uint256 blue
  ) external view returns (string memory) {
    string[6] memory parts;
    unchecked {
      uint256 a = red / 16;
      uint256 b = red % 16;
      parts[0] = decimalToHex[a];
      parts[1] = decimalToHex[b];

      uint256 c = green / 16;
      uint256 d = green % 16;
      parts[2] = decimalToHex[c];
      parts[3] = decimalToHex[d];

      uint256 e = blue / 16;
      uint256 f = blue % 16;
      parts[4] = decimalToHex[e];
      parts[5] = decimalToHex[f];
    }

    string memory output = string(
      abi.encodePacked(
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5]
      )
    );
    return output;
  }

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}

library Base64 {
  bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}