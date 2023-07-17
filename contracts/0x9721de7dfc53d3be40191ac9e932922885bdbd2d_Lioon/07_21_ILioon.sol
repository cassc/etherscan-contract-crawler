// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ILioon {

    // struct to store each token's traits
    struct TokenMetadata {
        bool isLion;
        uint8 alpha;
    }

    function getPaidTokens() external view returns (uint256);
}