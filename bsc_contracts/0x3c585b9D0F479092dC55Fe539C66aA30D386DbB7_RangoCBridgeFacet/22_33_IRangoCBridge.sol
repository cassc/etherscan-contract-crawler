// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./Interchain.sol";
import "../libraries/LibSwapper.sol";

/// @title An interface to RangoCBridge.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoCBridge {
    enum CBridgeBridgeType {TRANSFER, TRANSFER_WITH_MESSAGE}
    /// @param receiver The receiver address in the destination chain. For interchain message, receiver is the dApp contract address on destination, not recipient
    /// @param dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    struct CBridgeBridgeRequest {
        CBridgeBridgeType bridgeType;
        address receiver;
        uint64 dstChainId;
        uint64 nonce;
        uint32 maxSlippage;
        uint sgnFee;
        bytes imMessage;
    }

    function cBridgeBridge(
        IRango.RangoBridgeRequest memory request,
        CBridgeBridgeRequest calldata bridgeRequest
    ) external payable;

    function cBridgeSwapAndBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        CBridgeBridgeRequest calldata bridgeRequest
    ) external payable;

}