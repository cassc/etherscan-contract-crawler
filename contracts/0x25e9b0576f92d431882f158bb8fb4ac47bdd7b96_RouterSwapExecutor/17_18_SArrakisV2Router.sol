// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-version
pragma solidity >=0.8.0;

import {PermitTransferFrom, PermitBatchTransferFrom} from "./SPermit2.sol";

struct AddLiquidityData {
    uint256 amount0Max;
    uint256 amount1Max;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 amountSharesMin;
    address vault;
    address receiver;
    address gauge;
}

struct RemoveLiquidityData {
    uint256 burnAmount;
    uint256 amount0Min;
    uint256 amount1Min;
    address vault;
    address payable receiver;
    address gauge;
    bool receiveETH;
}

struct SwapData {
    bytes swapPayload;
    uint256 amountInSwap;
    uint256 amountOutSwap;
    address swapRouter;
    bool zeroForOne;
}

struct SwapAndAddData {
    SwapData swapData;
    AddLiquidityData addData;
}

struct AddLiquidityPermit2Data {
    AddLiquidityData addData;
    PermitBatchTransferFrom permit;
    bytes signature;
}

struct RemoveLiquidityPermit2Data {
    RemoveLiquidityData removeData;
    PermitTransferFrom permit;
    bytes signature;
}

struct SwapAndAddPermit2Data {
    SwapAndAddData swapAndAddData;
    PermitBatchTransferFrom permit;
    bytes signature;
}

struct MintRules {
    uint256 supplyCap;
    bool hasWhitelist;
}