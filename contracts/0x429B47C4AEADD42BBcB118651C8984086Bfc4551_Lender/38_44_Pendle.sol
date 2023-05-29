// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

library Pendle {
    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain;
        uint256 maxIteration;
        uint256 eps;
    }

    struct TokenInput {
        // Token/Sy data
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        address bulk;
        // Kyber data
        address kyberRouter;
        bytes kybercall;
    }
}