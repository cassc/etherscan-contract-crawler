// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import {ICutUpGeneration} from "./interfaces/ICutUpGeneration.sol";

interface ITerraNullius {
    struct Claim {
        address claimant;
        string message;
        uint blockNumber;
    }

    // Claim[] public claims;
    function claims(uint256) external view returns (address, string memory, uint256);
}

contract CutUpGeneration is ICutUpGeneration {
    ITerraNullius public terraNullius;
    uint256 public maxSupply = 4621;

    constructor(address terraNulliusAddress) {
        terraNullius = ITerraNullius(terraNulliusAddress);
    }

    function cutUp(bytes32 seed) external view returns (ICutUpGeneration.Messages memory) {
        uint256 n;
        if (seed.length == 0) {
            n = uint256(blockhash(block.number - 1));
        } else {
            n = uint256(seed);
        }

        return ICutUpGeneration.Messages(
            getMessage(((n << 240) >> 240) % maxSupply),
            getMessage(((n << 224) >> 240) % maxSupply),
            getMessage(((n << 208) >> 240) % maxSupply),
            getMessage(((n << 192) >> 240) % maxSupply),
            getMessage(((n << 176) >> 240) % maxSupply),
            getMessage(((n << 160) >> 240) % maxSupply),
            getMessage(((n << 144) >> 240) % maxSupply),
            getMessage(((n << 128) >> 240) % maxSupply),
            getMessage(((n << 112) >> 240) % maxSupply),
            getMessage(((n << 96) >> 240) % maxSupply),
            getMessage(((n << 80) >> 240) % maxSupply),
            getMessage(((n << 64) >> 240) % maxSupply)
        );
    }

    function getMessage(uint256 index) private view returns (string memory) {
        try terraNullius.claims(index) returns (address, string memory message, uint256) {
            return Base64.encode(bytes(message));
        } catch {
            return "";
        }
    }
}