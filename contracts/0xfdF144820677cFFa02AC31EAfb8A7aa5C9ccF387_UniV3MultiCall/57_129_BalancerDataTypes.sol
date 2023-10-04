// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IBalancerAsset} from "./IBalancerAsset.sol";

library BalancerDataTypes {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IBalancerAsset assetIn;
        IBalancerAsset assetOut;
        uint256 amount;
        bytes userData;
    }
}