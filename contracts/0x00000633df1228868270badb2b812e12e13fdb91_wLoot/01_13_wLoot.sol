// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Base64.sol";

contract wLoot is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdCounter;

    uint256 private constant maxTokensPerTransaction = 10;
    uint256 private tokenPrice = 30000000000000000; // 0.03 ETH
    uint256 private constant nftsNumber = 8100;
    uint256 private constant freeNumber = 1000;
    uint256 private constant startBlock = 13159326;

    mapping(uint256 => uint256) private randomNumber;

    constructor() ERC721("wLoot", "WLOOT") {}

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function buy(uint256 tokensNumber) public payable {
        require(block.number >= startBlock, "not start");
        require(tokenIdCounter.current() + tokensNumber <= nftsNumber, "Exceed total");
        require(tokensNumber > 0, "Wrong amount");
        require(
            tokensNumber <= maxTokensPerTransaction,
            "Max tokens per transaction number exceeded"
        );
        
        if (tokenIdCounter.current() >= freeNumber) {
            require(
                tokenPrice * tokensNumber <= msg.value,
                "Ether value sent is too low"
            );
        }

        for (uint256 i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, tokenIdCounter.current());
            randomNumber[tokenIdCounter.current()] = random(
                string(abi.encodePacked(tokenIdCounter.current(), block.number))
            );
            tokenIdCounter.increment();
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getLongitude(uint256 tokenId) public view returns (string memory) {
        require(tokenId < tokenIdCounter.current(), "tokenId is not exist");
        uint256 l = tokenId % 90;
        if (l < 45) {
            return
                string(
                    abi.encodePacked(
                        toString(l * 4),
                        "W",
                        "-",
                        toString(l * 4 + 4),
                        "W"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        toString((l - 45) * 4),
                        "E",
                        "-",
                        toString((l - 44) * 4),
                        "E"
                    )
                );
        }
    }

    function getLatitude(uint256 tokenId) public view returns (string memory) {
        require(tokenId < tokenIdCounter.current(), "tokenId is not exist");
        uint256 l = tokenId / 90;
        if (l < 45) {
            return
                string(
                    abi.encodePacked(
                        toString(l * 2),
                        "N",
                        "-",
                        toString(l * 2 + 2),
                        "N"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        toString((l - 45) * 2),
                        "S",
                        "-",
                        toString((l - 44) * 2),
                        "S"
                    )
                );
        }
    }

    function getGold(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GOLD");
    }

    function getIron(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "IRON");
    }

    function getCoal(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "COAL");
    }

    function getAgriculture(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "AGRICULTURE");
    }

    function getWater(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WATER");
    }

    function getOil(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OIL");
    }

    function getPopulation(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "POPULATION");
    }

    function getDiamond(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DIAMOND");
    }

    function pluck(uint256 tokenId, string memory keyPrefix)
        internal
        view
        returns (string memory)
    {
        require(tokenId < tokenIdCounter.current(), "tokenId is not exist");
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, randomNumber[tokenId]))
        );
        return toString(rand % 100);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[21] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">Longitude: ';

        parts[1] = getLongitude(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">Latitude: ';

        parts[3] = getLatitude(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">Gold: ';

        parts[5] = getGold(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">Iron: ';

        parts[7] = getIron(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">Coal: ';

        parts[9] = getCoal(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">Agriculture: ';

        parts[11] = getAgriculture(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">Water: ';

        parts[13] = getWater(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">Oil: ';

        parts[15] = getOil(tokenId);

        parts[16] = '</text><text x="10" y="180" class="base">Population: ';

        parts[17] = getPopulation(tokenId);

        parts[18] = '</text><text x="10" y="200" class="base">Diamond: ';

        parts[19] = getDiamond(tokenId);

        parts[20] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8],
                parts[9]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16],
                parts[17],
                parts[18],
                parts[19],
                parts[20]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "wLoot #',
                        toString(tokenId),
                        '", "description": "wLoot is randomized adventurer land generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use wLoot in any way you want. Part of the larger Loot Project metaverse.", "image": "data:image/svg+xml;base64,',
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