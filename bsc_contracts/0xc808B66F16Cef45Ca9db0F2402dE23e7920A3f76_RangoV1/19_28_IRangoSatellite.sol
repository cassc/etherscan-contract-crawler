// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Interchain.sol";

/// @title An interface to RangoSatellite.sol contract to improve type hinting
/// @author Hellboy
interface IRangoSatellite {

    enum SatelliteBridgeType { TRANSFER, TRANSFER_WITH_MESSAGE }

    /// @param receiver The receiver address in the destination chain
    /// @param toChainId The network id of destination chain, ex: 56 for BSC
    struct SatelliteBridgeRequest {
        SatelliteBridgeType _bridgeType;

        address receiver;
        uint256 toChainId;
        string toChain;
        string symbol;
        uint256 relayerGas;
        Interchain.RangoInterChainMessage imMessage;
    }

    /// @notice Executes a bridging via satellite
    /// @param _request The extra fields required by the satellite bridge
    /// @param _token The requested token to bridge
    /// @param _amount The requested amount to bridge
    function satelliteBridge(address _token, uint256 _amount, SatelliteBridgeRequest memory _request) external payable;
}