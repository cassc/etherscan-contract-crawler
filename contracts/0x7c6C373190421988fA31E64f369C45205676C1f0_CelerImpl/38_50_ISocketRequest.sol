// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketRoute
 * @notice Interface with Request DataStructures to invoke controller functions.
 * @author Socket dot tech.
 */
interface ISocketRequest {
    struct SwapMultiBridgeRequest {
        uint32 swapRouteId;
        bytes swapImplData;
        uint32[] bridgeRouteIds;
        bytes[] bridgeImplDataItems;
        uint256[] bridgeRatios;
        bytes[] eventDataItems;
    }

    // Datastructure for Refuel-Swap-Bridge function
    struct RefuelSwapBridgeRequest {
        uint32 refuelRouteId;
        bytes refuelData;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }

    // Datastructure for DeductFees-Swap function
    struct FeesTakerSwapRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 routeId;
        bytes swapRequestData;
    }

    // Datastructure for DeductFees-Bridge function
    struct FeesTakerBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 routeId;
        bytes bridgeRequestData;
    }

    // Datastructure for DeductFees-MultiBridge function
    struct FeesTakerMultiBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32[] bridgeRouteIds;
        bytes[] bridgeRequestDataItems;
    }

    // Datastructure for DeductFees-Swap-Bridge function
    struct FeesTakerSwapBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }

    // Datastructure for DeductFees-Refuel-Swap-Bridge function
    struct FeesTakerRefuelSwapBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 refuelRouteId;
        bytes refuelData;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }
}