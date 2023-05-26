// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import {Strings} from "./Strings.sol";
import {WildNFT} from "./WildNFT.sol";
import {Base64} from "./Base64.sol";
import {Math} from "./Math.sol";

contract Lux is WildNFT {
    uint256 public CYCLE_SECONDS = 1969920; // 22.8 days * 24 hours * 60 minutes * 60 seconds
    uint256 _maxSupply = 176;

    constructor(address _minter) WildNFT("LUX", "LUX", _minter, _maxSupply) {}

    function randomIndices(uint256 count)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory numbers = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            numbers[j] = j;
        }
        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.timestamp / CYCLE_SECONDS )) 
        );
        for (uint256 i = 0; i < numbers.length; i++) {
            uint256 n = i + ((seed >> i) % (numbers.length - i));
            uint256 temp = numbers[n];
            numbers[n] = numbers[i];
            numbers[i] = temp;
        }
        return numbers;
    }

    /**
     Returns i % n and making sure the result is positive. Eg -1 % 44 => 43
     */
    function posMod(int256 i, int256 n) private pure returns (uint256) {
        int256 result = i % n;
        if (result < 0) {
            return uint256(result + n);
        }
        return uint256(result);
    }

    // each token is in one of four batches [0,1,2,3]
    // each batch has 44 tokens (44x4=176 total)
    // every CYCLE_SECONDS, the img assigned to each token changes, depending on the algo
    // for that batch
    // batch 0: 0-43, increments up 1 every CYCLE_SECONDS (43 goes to 0)
    // batch 1: 44-87, each img randomly assigned to each token every CYCLE_SECONDS
    // batch 2: 88-153, decrements down 1 every CYCLE_SECONDS (88 goes to 153)
    // batch 3: 154-175, never changes, always the same img
    function image(uint256 tokenId) public view returns (uint256) {
        uint256 cycles = block.timestamp / CYCLE_SECONDS;
        uint256 result;
        if (tokenId < 44) {
            result = posMod(int256(tokenId + cycles), 44);
        } else if (tokenId < 88) {
            uint256[] memory indices = randomIndices(44);
            result = 44 + indices[tokenId - 44]; 
        } else if (tokenId < 154) {
            cycles = block.timestamp / (CYCLE_SECONDS * 2 / 3);
            result = 88 + posMod(int256(tokenId) - int256(cycles), 66); 
        } else {
            result = tokenId;
        }
        return result;
    }

    // tokenURI function returns json metadata for the token
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");
        string
            memory imgUrl = "https://static.wild.xyz/tokens/unrevealed/assets/unrevealed.webp";
        string memory name = string(
            abi.encodePacked("LUX ", Strings.toString(tokenId))
        );

        // styleGroup 1,2,3, or 4
        string memory phase = Strings.toString(4);
        string memory phase_time = "N/A";
        string memory phase_type = "STATIC";
        if (tokenId < 44) {
            phase = Strings.toString(1);
            phase_time = "22 DAYS";
            phase_type = "ASCENDING";
        } else if (tokenId < 88) {
            phase = Strings.toString(2);
            phase_time = "22 DAYS";
            phase_type = "RANDOM";
        } else if (tokenId < 154) {
            phase = Strings.toString(3);
            phase_time = "15 DAYS";
            phase_type = "DESCENDING";
        }
        string memory externalUrl = string.concat(
            "https://wild.xyz/loucas-braconnier/lux/",
            Strings.toString(tokenId)
        );
        string
            memory description = "LUX is a collection of 176 photographs split into four distinct phases. The sun's eleven-year oscillation is a dynamic unifying factor for all phases. Similar to four movements of a larger composition, each phase is a closed system. The images contained in a phase presaged the others. They cycle across tokens but are restricted to their own set of loops. Still, a few have broken out and remain petrified.";
        string memory attributesStr = "";
        if (bytes(baseURI).length > 0) {
            string memory imgStr = Strings.toString(image(tokenId));
            imgUrl = string(abi.encodePacked(baseURI, imgStr, ".jpg"));
            name = string(abi.encodePacked("LUX ", imgStr));
            attributesStr = string.concat(
                ',"attributes":[{"trait_type":"PHASE","value":"',
                phase,
                '"},{"trait_type":"PHASE TYPE","value":"',
                phase_type,
                '"},{"trait_type":"PHASE TIME","value":"',
                phase_time,
                '"}]'
            );
        }
        string memory json = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '", "description": "',
                    description,
                    '", "image": "',
                    imgUrl,
                    '", "external_url": "',
                    externalUrl,
                    '"',
                    attributesStr,
                    "}"
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}