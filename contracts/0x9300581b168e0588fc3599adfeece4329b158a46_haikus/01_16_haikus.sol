// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./recovery/recovery.sol";


contract haikus is ERC721Enumerable, ReentrancyGuard, Ownable, recovery {

    mapping (address => bool)                      public friendly;
    mapping (address => mapping(uint256 => bool )) public used;

    uint256              admins       = 0;
    uint256              friendlies   = 500;
    uint256              freebies     = 3000;
    uint256              payingGuests = 8000;

    string[] private titleWords1 = ["A sign", "Graffiti", "Random writing", "A scrawl", "A framed haiku"];
    string[] private titleWords2 = ["on the wall", "in a book", "on the ceiling", "on the floor", "in a drawer"];
    string[] private titleWords3 = ["a teahouse", "the railway station", "the post office", "an opera house", "a public toilet"];
    string[] private titleWords4 = ["Tokyo", "Osaka", "Kyoto", "Yokohama", "Sydney","Nagoya","Brussels"];


    string[] private wordList1 = ["Enchanting", "Amazing", "Colourful", "Delightful", "Delicate"];
    string[] private wordList2 = ["visions", "distance", "conscience", "process", "chaos"];
    string[] private wordList3 = ["superstitious", "contrasting", "graceful", "inviting", "contradicting", "overwhelming"];
    string[] private wordList4 = ["true", "dark", "cold", "warm", "great"];
    string[] private wordList5 = ["scenery","season", "colours","lights","Spring","Winter","Summer","Autumn"];
    string[] private wordList6 = ["undeniable", "beautiful", "irreplaceable", "unbelievable", "irrevocable"];
    string[] private wordList7 = ["inspiration", "imagination", "wisdom", "thoughts"];

    string[] private footer1 = ["Memoirs", "Diary", "Recollections", "Mumblings"];
    string[] private footer2 = ["geisha", "samourai", "serf", "tinker"];


    constructor(address[] memory _friendlies)
        ERC721("Golden Haikus", "GHK")
    {
        for (uint i = 0; i < _friendlies.length; i++) {
            friendly[_friendlies[i]] = true;
        }
    }

    function getTW1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Title1", titleWords1);
    }
   function getTW2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Title2", titleWords2);
    }

    function getTW3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Title3", titleWords3);
    }

    function getTW4(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Title4", titleWords4);
    }


    function getL1W1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Line1W1", wordList1);
    }
    function getL1W2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Line1W1", wordList2);
    }
    function getL2W1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Line1W1", wordList3);
    }
    function getL2W2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Line1W1", wordList4);
    }
    function getL2W3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Line1W1", wordList5);
    }
    function getL3W1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Line1W1", wordList6);
    }
    function getL3W2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Line1W1", wordList7);
    }

    function getFooterW1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "F1", footer1);
    }

    function getFooterW2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "F2", footer2);
    }


    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    keyPrefix,
                    tokenId,
                    block.timestamp,
                    block.difficulty
                )
            )
        );
        string memory output = sourceArray[rand % sourceArray.length];

        return output;
    }

    function GetLine1(uint256 tokenId) internal view returns (string memory) {
        string[5] memory parts;
        parts[0] = "";
        parts[1] = getL1W1(tokenId);
        parts[2] = " ";
        parts[3] = getL1W2(tokenId);
        parts[4] = ",\n";
        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4]
                )
            );
    }

    function GetLine2(uint256 tokenId) internal view returns (string memory) {
        string[7] memory parts;
        parts[0] = "";
        parts[1] = getL2W1(tokenId);
        parts[2] = " ";
        parts[3] = getL2W2(tokenId);
        parts[4] = " ";
        parts[5] = getL2W3(tokenId);
        parts[6] = ",\n";
        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4],
                    parts[5],
                    parts[6]
                )
            );
    }

    function GetLine3(uint256 tokenId) internal view returns (string memory) {
        string[5] memory parts;
        parts[0] = "";
        parts[1] = getL3W1(tokenId);
        parts[2] = " ";
        parts[3] = getL3W2(tokenId);
        parts[4] = ",\n";
        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4]
                )
            );
    }

    function GetPrefix(uint256 tokenId, bool addCR) internal view returns (string memory) {
        string memory cr = "\n\n";
        if (!addCR) cr = "";
        string[9] memory parts;
        parts[0] = "";
        parts[1] = getTW1(tokenId);
        parts[2] = " found ";
        parts[3] = getTW2(tokenId);
        parts[4] = " in ";
        parts[5] = getTW3(tokenId);
        parts[6] = " somewhere in ";
        parts[7] = getTW4(tokenId);
        parts[8] = cr;
        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4],
                    parts[5],
                    parts[6],
                    parts[7],
                    parts[8]

                )
            );

    }

    function GetTail(uint256 tokenId) internal view returns (string memory) {
        string[4] memory parts;

        parts[0] = getFooterW1(tokenId);
        parts[1] = " of a ";
        parts[2] = getFooterW2(tokenId);
        parts[3] = ", 1847";
        

        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3]
                )
            );
    }


    function GetBody(uint256 tokenId) internal view returns (string memory) {
        string[6] memory parts;

        parts[0] = GetPrefix(tokenId,true);
        parts[1] = GetLine1(tokenId);
        parts[2] = GetLine2(tokenId);
        parts[3] = GetLine3(tokenId);
        parts[4] = "\n\n";
        parts[5] = GetTail(tokenId);

        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4]
                )
            );
    }


    function test_alt(uint256 tokenId) internal view returns (string memory) {
        string memory part1 = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 150"><style>.base { fill: white; font-family: serif; font-size: 10px; }</style><defs><radialGradient id="grad1" cx="50%" cy="50%" r="50%" fx="50%" fy="50%"><stop offset="0%" style="stop-color:rgb(255,127,127); stop-opacity:0" /><stop offset="100%" style="stop-color:rgb(0,127,127);stop-opacity:1" /></radialGradient><linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1" /><stop offset="100%" style="stop-color:rgb(255,0,0);stop-opacity:1" /></linearGradient></defs><rect width="100%" height="100%" fill="url(#grad1)" /><text x="10" y="20" class="base">',
            GetPrefix(tokenId,true),
            '</text><text x="10" y="60" class="base">',
            GetLine1(tokenId),
            '</text><text x="10" y="80" class="base">',
            GetLine2(tokenId),
            '</text><text x="10" y="100" class="base">',
            GetLine3(tokenId)
        )) ;
        string memory part2 = string(abi.encodePacked(
            '</text><text x="10" y="130" class="base">',
            GetTail(tokenId),
            '</text><ellipse cx="350" cy="115" rx="35" ry="20" fill="url(#grad2)" /></svg>'
        )) ;
        string memory output = string(abi.encodePacked(part1,part2));

        // string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        // output = string(abi.encodePacked(output, parts[9], parts[10]));
        //output = string(abi.encodePacked(output, parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        // string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        // output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function tokenURI2(uint256 tokenId)
        public
        view
        
        returns (string memory)
    {

        string memory output = test_alt(tokenId);

        string memory story = GetBody(tokenId);

        string memory json = 
            
                string(
                    abi.encodePacked(
                        '{"name": "',
                        GetPrefix(tokenId,false),
                        " # ",
                        toString(tokenId),
                        '", "description": "',
                        story,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                
            
        );
        // output = string(
        //     abi.encodePacked("data:application/json;base64,", json)
        // );

        return json;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {

        string memory output = test_alt(tokenId);

        string memory story = GetBody(tokenId);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Golden Haiku # ',
                        toString(tokenId),
                        '", "description": "Golden Haikus : the random experience of serendipity", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function payingClaim() public payable nonReentrant {
        require(msg.value >= 1e16, "Minimum contribution 0.01 ETH");
        require(payingGuests >= 8000 , "Token ID invalid");
        _safeMint(_msgSender(), payingGuests++);
    }

    function freeClaim() public nonReentrant {
        require(freebies  < 8888, "Token ID invalid");
        _safeMint(_msgSender(), freebies++);
    }

    function friendClaim(address token, uint256 tokenId) public nonReentrant { 
        require(
            _msgSender() == IERC721(token).ownerOf(tokenId),
            "You do not own this token"
        );
        require(
            friendly[token],
            "This is not a friendly token"
        );
        require(!used[token][tokenId],"You have claimed with this friend before");
        used[token][tokenId] = true;
        require(friendlies < 3000, "all friendly tokens minted");
        _safeMint(_msgSender(),friendlies++);
    }

    function ownerClaim() public nonReentrant onlyOwner {
        require(admins < 500, "all admin tokens minted");
        _safeMint(_msgSender(), admins++);
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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

    // function tokenURI2(uint256 tokenId) override public view returns (string memory) {
      
        
    //     string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    //     output = string(abi.encodePacked('data:application/json;base64,', json));

    //     return output;
    // }
}