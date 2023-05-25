// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.4;
 
 library MetaHeroGeneGenerator {

    struct Gene {
        uint256 lastRandom;
    }

    function random(Gene storage g) internal returns (uint256) {
        unchecked {
            g.lastRandom = uint256(keccak256(abi.encode(keccak256(abi.encodePacked(msg.sender, tx.origin, gasleft(), g.lastRandom, block.timestamp, block.number, blockhash(block.number), blockhash(block.number-100))))));
        }
        return g.lastRandom;
    }
}