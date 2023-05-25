// SPDX-License-Identifier: MIT
// @authors Samee Siddiqui / Tristan Barrett

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";

contract Fives is ERC721Enumerable, ReentrancyGuard, Ownable {
    string[] private pointGuards = [
        "MAGIC JOHNSON",
        "JERRY WEST",
        "STEVE NASH",
        "ALLEN IVERSON",
        "JOHN STOCKTON",
        "ISIAH THOMAS",
        "STEPH CURRY",
        "KYRIE IRVING",
        "CHRIS PAUL",
        "RUSSELL WESTBROOK",
        "DAMIAN LILLARD",
        "DERRICK ROSE",
        "JRUE HOLIDAY",
        "RAJON RONDO",
        "OSCAR ROBERTSON",
        "LUKA DONCIC",
        "JA MORANT",
        "LAMELO BALL",
        "DELONTE WEST"
    ];

    string[] private shootingGuards = [
        "MICHAEL JORDAN",
        "KOBE BRYANT",
        "DWYANE WADE",
        "RAY ALLEN",
        "REGGIE MILLER",
        "JAMES HARDEN",
        "KLAY THOMPSON",
        "MANU GINOBILI",
        "BRADLEY BEAL",
        "DEVIN BOOKER",
        "JIMMY BUTLER",
        "VINCE CARTER",
        "TRACY MCGRADY",
        "LANCE STEPHENSON",
        "NICK YOUNG",
        "SETH CURRY"
    ];

    string[] private smallForwards = [
        "LEBRON JAMES",
        "KEVIN DURANT",
        "LARRY BIRD",
        "PAUL GEORGE",
        "KAWHI LEONARD",
        "SCOTTIE PIPPEN",
        "DOMINIQUE WILKINS",
        "JULIUS ERVING",
        "PAUL PIERCE",
        "GIANNIS ANTETOKOUNMPO",
        "CARMELO ANTHONY",
        "METTA WORLD PEACE",
        "OTTO PORTER",
        "ANDRE IGOUDALA"
    ];

    string[] private powerForwards = [
        "KARL MALONE",
        "TIM DUNCAN",
        "CHARLES BARKLEY",
        "DENNIS RODMAN",
        "KEVIN GARNETT",
        "DIRK NOWITZKI",
        "BLAKE GRIFFIN",
        "ANTHONY DAVIS",
        "ZION WILLIAMSON",
        "DRAYMOND GREEN",
        "PAU GASOL",
        "LAMAR ODOM",
        "BRIAN SCALABRINE",
        "SHAWN KEMP",
        "AMARE STOUDEMIRE"
    ];

    string[] private centers = [
        "SHAQUILLE O'NEAL",
        "KAREEM ABDUL-JABBAR",
        "WILT CHAMBERLAIN",
        "BILL RUSSELL",
        "HAKEEM OLAJUWON",
        "DAVID ROBINSON",
        "PATRICK EWING",
        "JAVALE MCGEE",
        "DWIGHT HOWARD",
        "DIKEMBE MUTOMBO",
        "YAO MING",
        "BEN WALLANCE",
        "BILL LAIMBEER",
        "KENDRICK PERKINS",
        "JOEL EMBIID",
        "KWAME BROWN"
    ];

    string[] private legendaryBackcourt = [
        "TRAGIC BRONSON",
        "HALFCOURT STEPH",
        "MOUTHGUARD STEPH",
        "SPLASH BROS STEPH",
        "CRYPTO OG DINWIDDIE",
        "POINT GOD LEBRON",
        "IVERSON FINALS STEP OVER",
        "CHEF CURRY",
        "MVP D ROSE",
        "UNCLE DREW",
        "BASEBALL JORDAN",
        "EARTH IS FLAT KYRIE",
        "PLAYOFF RONDO",
        "DESERT EAGLE ARENAS",
        "THE BEARD"
    ];

    string[] private legendaryWings = [
        "SPACE JAM 2 LEBRON",
        "HEATLES LEBRON",
        "GM LEBRON",
        "SPLASH BROS KLAY",
        "KAWHI'S ROBOT LAUGH",
        "YOU DA REAL MVP KD",
        "DOWN 3-1 LEBRON",
        "RON ARTEST AT THE PALACE",
        "FINALS MVP IGOUDALA",
        "81 PT KOBE",
        "BLACK MAMBA",
        "FLU GAME JORDAN",
        "DUNK CONTEST VINCE CARTER",
        "13 PTS IN 33 SECS MCGRADY",
        "TOOK IT PERSONAL JORDAN",
        "SPACE JAM JORDAN",
        "JR SMITH SHOT SELECTION",
        "NO FLINCH KOBE"
    ];

    string[] private legendaryBigMen = [
        "SHAQ TAKING FREETHROWS",
        "SHAQ BREAKING BACKBOARDS",
        "VEGAS RODMAN",
        "THE WHITE MAMBA",
        "SNAKE KD",
        "SHAQTIN MVP JAVALE",
        "100 PT GAME WILT",
        "THE BROW",
        "THE GREEK FREAK",
        "FINALS DIRK",
        "DRAYMOND BUT NOT UGLY",
        "BLAKE POSTERIZING THE NBA",
        "ANTHING IS POSSIBLE KG",
        "EJECTED RASHEED WALLACE"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getPG(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "POINT GUARD", pointGuards, legendaryBackcourt);
    }

    function getSG(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SHOOTING GUARD", shootingGuards, legendaryWings);
    }

    function getSF(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SMALL FORWARD", smallForwards, legendaryWings);
    }

    function getPF(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "POWER FORWARD", powerForwards, legendaryBigMen);
    }

    function getC(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CENTER", centers, legendaryBigMen);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray, string[] memory legendsArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        uint256 greatness = rand % 21;

        string memory output = sourceArray[rand % sourceArray.length];
        if (greatness >= 19) {
            output = legendsArray[rand % legendsArray.length];
        }

        return output;
    }
    
    function getFullTextElem(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray, string[] memory legendsArray, string memory yVal) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        bool isRare = (rand % 21) >= 19;
        string memory textOpen = '<text x="30" y=';
        string memory classType = isRare ? 'class="rare">' : 'class="base">';
        string memory player = pluck(tokenId, keyPrefix, sourceArray, legendsArray);
        string memory closingTag = '</text>';
        return string(abi.encodePacked(textOpen, yVal, classType, player, closingTag));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base {fill: white; font-family: Helvetica; font-weight: bold; font-size: 20px; } .rare {fill: #ff0612; font-family: Helvetica; font-weight: bold; font-size: 20px; }</style><rect width="100%" height="100%" fill="#000" style="stroke: #ff0612; stroke-width: 24;" />';
        
        parts[1] = getFullTextElem(tokenId, "POINT GUARD", pointGuards, legendaryBackcourt, '"70" ');
        parts[2] = getFullTextElem(tokenId, "SHOOTING GUARD", shootingGuards, legendaryWings, '"95" ');
        parts[3] = getFullTextElem(tokenId, "SMALL FORWARD", smallForwards, legendaryWings, '"120" ');
        parts[4] = getFullTextElem(tokenId, "POWER FORWARD", powerForwards, legendaryBigMen, '"145" ');
        parts[5] = getFullTextElem(tokenId, "CENTER", centers, legendaryBigMen, '"170" ');

        parts[6] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Fives #', toString(tokenId), '", "description": "Fives is a randomized lineup of the best ballers in history stored on chain. Stats, images, and other functionality are intentionally omitted.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7900, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7899 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
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

    constructor() ERC721("Fives", "FIVES") Ownable() {}
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