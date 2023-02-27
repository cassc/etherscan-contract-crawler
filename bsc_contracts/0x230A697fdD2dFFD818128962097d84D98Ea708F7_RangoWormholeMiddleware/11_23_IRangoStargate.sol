// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./IStargateRouter.sol";
import "./Interchain.sol";
import "./IRango.sol";
import "../libraries/LibSwapper.sol";

/// @title An interface to interact with RangoStargateFacet
/// @author Uchiha Sasuke
interface IRangoStargate {
    enum StargateBridgeType {TRANSFER, TRANSFER_WITH_MESSAGE}

    struct StargateRequest {
        StargateBridgeType bridgeType;
        uint16 dstChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        address payable srcGasRefundAddress;
        uint256 minAmountLD;

        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;

        bytes to;
        uint stgFee;

        bytes imMessage;
    }

    function stargateSwapAndBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        IRangoStargate.StargateRequest memory stargateRequest
    ) external payable;

    function stargateBridge(
        IRangoStargate.StargateRequest memory stargateRequest,
        IRango.RangoBridgeRequest memory bridgeRequest
    ) external payable;
}