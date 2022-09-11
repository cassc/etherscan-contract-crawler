// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

/// @title Algocracy Random Registry
/// @author jolan.eth

abstract contract AlgocracyRandomRegistry {
    struct Random {
        uint256 id;
        uint256 provableRandom;
    }

    uint32 public FIXED_QTY = 1;
    uint16 public FIXED_TIC = 21;
    uint32 public FIXED_GAS = 2500000;

    uint256 randomIndex;
    mapping(uint256 => Random) public RandomRegistry;
    
    function getRandomRegistryLength()
    public view returns (uint256) {
        return randomIndex;
    }

    function getRandomRegistry(uint256 id)
    public view returns (Random memory) {
        return RandomRegistry[id];
    }

    function setRandomRegistration(uint256 id, uint256 provableRandom)
    internal {
        RandomRegistry[randomIndex++] = Random(
            id, provableRandom
        );
    }
}