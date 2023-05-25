// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Types {
    struct TokenGatedMintArgs {
        uint256 tokenId;
        uint256 amount;
        uint256 tokenGatedId;
        address pass;
    }

    struct MintArgs {
        uint256[] tokenIds;
        uint256[] amounts;
    }
}