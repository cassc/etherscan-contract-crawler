// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

/// @title Algocracy Pass Registry
/// @author jolan.eth

abstract contract AlgocracyPassRegistry {
    struct Pass {
        uint256 ACCESS_LEVEL;
        uint256 blockNumber;
    }

    bool public LOCK;
    
    uint256 public ACCESS_LEVEL_CORE = 42069;
    uint256 public ACCESS_LEVEL_VETOER = 444;
    uint256 public ACCESS_LEVEL_OPERATOR = 420;
    uint256 public ACCESS_LEVEL_BASE = 69;

    uint256 passIndex;
    mapping(uint256 => Pass) PassRegistry;

    function getAccessLevel(uint256 id)
    public view returns (uint256) {
        return PassRegistry[id].ACCESS_LEVEL;
    }

    function setPassRegistration(
        uint256 _ACCESS_LEVEL
    ) internal {
        if (passIndex == 0) passIndex = 1;
        Pass memory newPass = Pass(_ACCESS_LEVEL, block.number);
        PassRegistry[passIndex++] = newPass;
    }
}