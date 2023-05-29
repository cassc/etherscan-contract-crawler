// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import 'src/interfaces/IAny.sol';

library Element {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAny assetIn;
        IAny assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}