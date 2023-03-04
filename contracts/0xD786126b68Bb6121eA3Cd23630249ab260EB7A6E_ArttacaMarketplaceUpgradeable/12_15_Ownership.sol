// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (lib/Ownership.sol)

pragma solidity ^0.8.4;

/**
 * @title Ownership Marketplace library.
 */
library Ownership {
    bytes32 public constant SPLIT_TYPEHASH = keccak256("Split(address account,uint96 shares)");

    struct Split {
        address payable account;
        uint96 shares;
    }

    struct Royalties {
        Split[] splits;
        uint96 percentage;
    }

    function hash(Split memory split) internal pure returns (bytes32) {
        return keccak256(abi.encode(SPLIT_TYPEHASH, split.account, split.shares));
    }
}