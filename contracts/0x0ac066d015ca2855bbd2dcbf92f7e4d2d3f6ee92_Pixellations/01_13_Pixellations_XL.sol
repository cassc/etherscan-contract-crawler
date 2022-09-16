/*----------------------------------------------------------------

  ____ _____  _______ _     _        _  _____ ___ ___  _   _ ____  
 |  _ \_ _\ \/ / ____| |   | |      / \|_   _|_ _/ _ \| \ | / ___| 
 | |_) | | \  /|  _| | |   | |     / _ \ | |  | | | | |  \| \___ \ 
 |  __/| | /  \| |___| |___| |___ / ___ \| |  | | |_| | |\  |___) |
 |_|  |___/_/\_\_____|_____|_____/_/   \_\_| |___\___/|_| \_|____/ 


----------------------------------------------------------------*/

// Happy Ethereum Merge Day!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Pixellations is ERC721, Ownable {

    constructor() ERC721("Pixellations", "PXL") {
        tokenCount.increment();
    }

    using Counters for Counters.Counter;
    Counters.Counter private tokenCount;

    uint256 public maxSupply = 1024;

    struct Token {
        uint id;
        uint bigStars;
        uint whiteStars;
        uint redStars;
        uint purpleStars;
        uint blueStars;
        uint yellowStars;
        Star[] stars;
    }

    struct Star {
        uint size;
        uint x;
        uint y;
        string color;
        string opacity;
    }

    mapping(uint256 => Token) private tokens;

    string[10] private opacity = [
        '0.2', '0.2', '0.2', '0.2',
        '0.4', '0.4', '0.4',
        '0.8', '0.8',
        '1'
    ];

    uint256[5] private whiteStarOptions = [
        32, 40, 48, 56, 64
    ];
    
    uint256[100] private redStarOptions = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 3
        ];

    uint256[100] private purpleStarOptions = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 4
        ];

    uint256[100] private blueStarOptions = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 5
        ];

    uint256[100] private yellowStarOptions = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 5, 6
        ];


    function random(uint256 input, uint256 min, uint256 max) public view returns (uint256) {
        uint256 randRange = max - min;
        return max - (uint256(keccak256(abi.encodePacked(input, tokenCount.current(), msg.sender))) % randRange) - 1;
    }

    function totalSupply() public view returns (uint256) {
        return tokenCount.current() - 1;
    }

    function discoverStars(uint256 tokenId, uint256 seed, uint256 big, uint256 white, uint256 red, uint256 purple, uint256 blue, uint256 yellow) internal {

        uint bigStarRefX = random(seed, 0, 17);
        uint bigStarRefY = random(seed + 1, 0, 17);

        //Discover big stars
        for (uint256 i = 0; i < big; i++) {
            tokens[tokenId].stars.push(Star(2,random((seed+i), bigStarRefX, bigStarRefX + 31),random((seed+i+1), bigStarRefY, bigStarRefY + 31),"#FFF","1"));
        }

        //Discover white stars
        for (uint256 i = 0; i < white; i++) {
            tokens[tokenId].stars.push(Star(1,random(seed+i,0,64),random((seed+i+1),0,64),"#FFF",opacity[random(seed+i,0,10)]));
        }

        //Discover red stars
        for (uint256 i = 0; i < red; i++) {
            tokens[tokenId].stars.push(Star(1,random(seed+i+1,0,64),random((seed+i*3+1),0,64),"#FF8D8D","1"));
        }

        //Discover purple stars
        for (uint256 i = 0; i < purple; i++) {
            tokens[tokenId].stars.push(Star(1,random(seed+i*2,0,64),random((seed+i*4+1),0,64),"#D7A4FF","1"));
        }

        //Discover blue stars
        for (uint256 i = 0; i < blue; i++) {
            tokens[tokenId].stars.push(Star(1,random(seed+i/3,0,64),random((seed+i*5+1),0,64),"#7DD0FF","1"));
        }

        //Discover yellow stars
        for (uint256 i = 0; i < yellow; i++) {
            tokens[tokenId].stars.push(Star(1,random(seed+i-4,0,64),random((seed+i*6+1),0,64),"#FFE790","1"));
        }
    }

    function createToken(uint256 tokenId) private returns (Token storage) {

        uint256 seed = random(tokenId,1,65535);

        uint bigStars = random(seed,2,7);
        uint whiteStars = whiteStarOptions[random(seed,0,4)];
        uint redStars = redStarOptions[random(seed,0,100)];
        uint purpleStars = purpleStarOptions[random(seed,0,100)];
        uint blueStars = blueStarOptions[random(seed,0,100)];
        uint yellowStars = yellowStarOptions[random(seed,0,100)];

        Token storage token = tokens[tokenId];

        discoverStars(tokenId, seed, bigStars, whiteStars, redStars, purpleStars, blueStars, yellowStars);
        token.id = tokenId;
        token.bigStars = bigStars;
        token.whiteStars = whiteStars;
        token.redStars = redStars;
        token.purpleStars = purpleStars;
        token.blueStars = blueStars;
        token.yellowStars = yellowStars;

        return token;
    }

    function mint() external {
        require(totalSupply() < maxSupply, "All tokens have been minted.");
        uint tokenId = tokenCount.current();
        tokens[tokenId] = createToken(tokenId);
        _safeMint(msg.sender, tokenId);
        tokenCount.increment();
    }

    function getMetadata(Token memory token) public pure returns (string memory metadata) {
        metadata = string(
            abi.encodePacked(
                metadata,
                '[{"trait_type":"Big Stars", "value":"',
                uint2str(token.bigStars),
                '"},',
                '{"trait_type":"White Stars", "value":"',
                uint2str(token.whiteStars),
                '"},',
                '{"trait_type":"Red Stars", "value":"',
                uint2str(token.redStars),
                '"},',
                '{"trait_type":"Purple Stars", "value":"',
                uint2str(token.purpleStars),
                '"},',
                '{"trait_type":"Blue Stars", "value":"',
                uint2str(token.blueStars),
                '"},',
                '{"trait_type":"Yellow Stars", "value":"',
                uint2str(token.yellowStars),
                '"}]'
            )
        );
    }

    function getStarSvgs(uint256 tokenId) public view returns (string memory svg) {
        for (uint256 i = 0; i < tokens[tokenId].stars.length; i++) {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<rect x="', uint2str(tokens[tokenId].stars[i].x),'" ',
                    'y="', uint2str(tokens[tokenId].stars[i].y),'" ',
                    'width="', uint2str(tokens[tokenId].stars[i].size),'" ',
                    'height="', uint2str(tokens[tokenId].stars[i].size),'" ',
                    'fill="', tokens[tokenId].stars[i].color,'" ',
                    'opacity="', tokens[tokenId].stars[i].opacity,'"></rect>'
                )
            );
        }
        return svg;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        Token memory token = tokens[tokenId];

        string memory svg = string(
            abi.encodePacked(
            '<svg id="',
            uint2str(tokenId),
            '" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 64 64" fill="#000"><rect x="0" y="0" width="64" height="64" fill="#000"></rect>',
            getStarSvgs(tokenId),
            '</svg>'
            )
        );

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Pixellation #',
                                    uint2str(tokenId),
                                    '", "description": "Pixellations are fully on-chain svg pixel constellations. Happy Ethereum Merge Day!",',
                                    '"image": "data:image/svg+xml;base64,',
                                    Base64.encode(bytes(string(svg))),
                                    '", "attributes":',
                                    getMetadata(token),
                                    '}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}