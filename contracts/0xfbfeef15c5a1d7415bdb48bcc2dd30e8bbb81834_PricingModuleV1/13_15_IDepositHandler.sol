// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDepositHandler {
    struct FungibleTokenDeposit {
        address tokenAddress;
        uint256 amount;
        bool isLP;
    }

    struct NonFungibleTokenDeposit {
        address tokenAddress;
        uint256 tokenId;
    }

    struct MultiTokenDeposit {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct V3LPData {
        address tokenAddress;
        address token0;
        address token1;
        uint128 liquidityToRemove;
        uint24 fee;
    }
}