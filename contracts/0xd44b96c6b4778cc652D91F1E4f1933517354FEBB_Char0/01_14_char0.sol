//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//          CCCCCCCCCCCCC HHHHHHHHH     HHHHHHHHH               AAA               RRRRRRRRRRRRRRRRR          0000000000
//       CCC::::::::::::C H:::::::H     H:::::::H              A:::A              R::::::::::::::::R       00::::::::::00
//     CC:::::::::::::::C H:::::::H     H:::::::H             A:::::A             R::::::RRRRRR:::::R    00::::::::::::::00
//    C:::::CCCCCCCC::::C HH::::::H     H::::::HH            A:::::::A            RR:::::R     R:::::R  0:::::::0000:::::::0
//   C:::::C       CCCCCC   H:::::H     H:::::H             A:::::::::A             R::::R     R:::::R  0::::::0    0::::::0
//  C:::::C                 H:::::H     H:::::H            A:::::A:::::A            R::::R     R:::::R  0:::::0      0:::::0
//  C:::::C                 H::::::HHHHH::::::H           A:::::A A:::::A           R::::RRRRRR:::::R   0:::::0   0::::::::0
//  C:::::C                 H:::::::::::::::::H          A:::::A   A:::::A          R:::::::::::::RR    0:::::0 0::::0:::::0
//  C:::::C                 H:::::::::::::::::H         A:::::A     A:::::A         R::::RRRRRR:::::R   0:::::0::::0 0:::::0
//  C:::::C                 H::::::HHHHH::::::H        A:::::AAAAAAAAA:::::A        R::::R     R:::::R  0::::::::0   0:::::0
//  C:::::C                 H:::::H     H:::::H       A:::::::::::::::::::::A       R::::R     R:::::R  0:::::0      0:::::0
//   C:::::C       CCCCCC   H:::::H     H:::::H      A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R  0::::::0    0::::::0
//    C:::::CCCCCCCC::::C HH::::::H     H::::::HH   A:::::A             A:::::A   RR:::::R     R:::::R  0:::::::0000:::::::0
//     CC:::::::::::::::C H:::::::H     H:::::::H  A:::::A               A:::::A  R::::::R     R:::::R   00::::::::::::::00
//       CCC::::::::::::C H:::::::H     H:::::::H A:::::A                 A:::::A R::::::R     R:::::R     00::::::::::00
//          CCCCCCCCCCCCC HHHHHHHHH     HHHHHHHHH AAAAAAA                 AAAAAAA RRRRRRRR     RRRRRRR       000000000

/// @title A ERC721 contract to create random maps and waypoints
/// @author Solid-Code
/// @notice This contract is heavily inspired by Dom Hofmann's Loot Project and allows for the on chain creation of base character stats for use in character sheets.
contract Char0 is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 constant PARTYCOST = .01 ether;

    uint256[2] private statOddsRange = [0, 100];

    uint8[100] public rolls =
    [
     6,
     7, 7, 7, 7,
     8, 8, 8, 8, 8, 8, 8,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    10,10,10,10,10,10,10,10,10,10,10,10,
    11,11,11,11,11,11,11,11,11,11,11,11,11,
    12,12,12,12,12,12,12,12,12,12,12,12,12,
    13,13,13,13,13,13,13,13,13,13,13,13,
    14,14,14,14,14,14,14,14,14,14,
    15,15,15,15,15,15,15,15,15,
    16,16,16,16,16,
    17,17,17,
    18
    ];

    mapping(address => uint256) public founders;
    address constant public M = 0x90f828778C90f799b08aEf5b625C5481fA438c16;
    address constant public L = 0xdFc3739354c5B99eC5fab9175c5412881C9D222e;
    address constant public D = 0xA783F2cEA4D10FC8B87Ab22dCf73932F80D01293;

    constructor() ERC721("Char0", "CHAR0") {
      founders[M] = 2; //10000-3n
      founders[L] = 1; //9999-3n
      founders[D] = 3; //9998-3n
    }

    function updateFounder(address _oldAddress, address _newAddress) public {
      require(_msgSender() == _oldAddress, "not yours");
      founders[_oldAddress] = 0;
      founders[_newAddress] = founders[_oldAddress];
    }

    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _statOddsRoll(uint256 tokenId, uint256 stat)
        internal
        view
        returns (uint256)
    {
        uint256 rand = _random(
            string(abi.encodePacked(Strings.toString(stat),Strings.toString(tokenId)))
        );
        return (rand % (statOddsRange[1] - statOddsRange[0])) + statOddsRange[0];
    }

    function getStat(uint256 tokenId, uint256 stat) public view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return stat < 6 ? rolls[_statOddsRoll(tokenId,stat)] : _statOddsRoll(tokenId,stat) + 1;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string[13] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 216 279"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">STR: ';

        parts[1] = Strings.toString(getStat(tokenId,0));

        parts[2] = '</text><text x="10" y="40" class="base">DEX: ';

        parts[3] = Strings.toString(getStat(tokenId,1));

        parts[4] = '</text><text x="10" y="60" class="base">CON: ';

        parts[5] = Strings.toString(getStat(tokenId,2));

        parts[6] = '</text><text x="10" y="80" class="base">INT: ';

        parts[7] = Strings.toString(getStat(tokenId,3));

        parts[8] = '</text><text x="10" y="100" class="base">WIS: ';

        parts[9] = Strings.toString(getStat(tokenId,4));

        parts[10] = '</text><text x="10" y="120" class="base">CHA: ';

        parts[11] = Strings.toString(getStat(tokenId,5));

        parts[12] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8], parts[9], parts[10], parts[11], parts[12]));

        string memory json = string(abi.encodePacked('"attributes": [{"trait_type" : "Strength","value" : "',parts[1],'"},{"trait_type" : "Dexterity","value" : "',parts[3],'"},{"trait_type" : "Constitution","value" : "',parts[5],'"},{"trait_type" : "Intelligence","value" : "',parts[7],'"},{"trait_type" : "Wisdom","value" : "',parts[9],'"},{"trait_type" : "Charisma","value" : "',parts[11],'"}]'));
        json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Char0 #', toString(tokenId), '","description": "Use your Char0 NFT for any RPG game, roll your stats and build heroes from there.",',json,',"image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));

        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function rollChar0(uint256 _tokenId) public nonReentrant {
        require(_tokenId > 0 && _tokenId < 9701, "Token ID invalid");
        _safeMint(_msgSender(), _tokenId);
    }

    function rollParty(uint256[4] memory _tokenIds) public payable nonReentrant {
        require(msg.value == PARTYCOST, "not paid");
        for(uint8 i=0;i<4;i++) {
          require(_tokenIds[i] > 0 && _tokenIds[i] < 9701, "Token ID invalid");
          _safeMint(_msgSender(), _tokenIds[i]);
        }
    }

    function founderRoll(uint256[] memory _tokenIds) public nonReentrant {
        for(uint256 i=0;i<_tokenIds.length;i++) {
              require(_tokenIds[i] > 9700 && _tokenIds[i] < 10001, "Token ID invalid");
              require( _tokenIds[i] % 3 == founders[address(_msgSender())] - 1, "not your's to mint");
              _safeMint(owner(), _tokenIds[i]);
        }
    }

    function withdraw() public onlyOwner{
      payable(address(owner())).transfer(address(this).balance);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
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