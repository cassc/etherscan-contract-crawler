// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Dexify Protocol.

    (c) Dexify Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title ParaSwap V5 IAugustusSwapper interface
interface IParaSwapV5AugustusSwapper {
    struct Route {
        uint256 index;//Adapter at which index needs to be used
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee;
        Route[] route;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    function multiSwap(SellData calldata) external payable returns (uint256);
}