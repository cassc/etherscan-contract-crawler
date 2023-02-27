// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Interchain.sol";
import "./IRango.sol";
import "../libraries/LibSwapper.sol";


/// @title An interface to RangoSatellite.sol contract to improve type hinting
/// @author 0xiden
interface IRangoSatellite {

    enum SatelliteBridgeType {TRANSFER, TRANSFER_WITH_MESSAGE}

    /// @dev symbol is case sensitive
    /// @param receiver The receiver address in the destination chain
    /// @param toChainId The network id of destination chain, ex: 56 for BSC
    /// @param toChain The name of the network, 'binance' for BSC
    /// @param symbol The name of token, 'axlUSDC'
    /// @param relayerGas The amount of native token to provide to relayer
    /// @param refundAddress The address to receive extra gas
    struct SatelliteBridgeRequest {
        SatelliteBridgeType bridgeType;

        string receiver;
        uint256 toChainId;
        string toChain;
        string symbol;
        uint256 relayerGas;
        address srcGasRefundAddress;
        bytes imMessage;
    }

    function satelliteSwapAndBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        IRangoSatellite.SatelliteBridgeRequest memory bridgeRequest
    ) external payable;

    function satelliteBridge(
        SatelliteBridgeRequest memory request,
        IRango.RangoBridgeRequest memory bridgeRequest
    ) external payable;
}