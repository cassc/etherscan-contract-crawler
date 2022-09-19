// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title An interface to RangoHyphen.sol contract to improve type hinting
/// @author Hellboy
interface IRangoHyphen {

    /// @param receiver The receiver address in the destination chain
    /// @param toChainId The network id of destination chain, ex: 56 for BSC
    struct HyphenBridgeRequest {
        address receiver;
        uint256 toChainId;
    }

    /// @notice Executes a bridging via hyphen
    /// @param _request The extra fields required by the hyphen bridge
    /// @param _token The requested token to bridge
    /// @param _amount The requested amount to bridge
    function hyphenBridge(HyphenBridgeRequest memory _request, address _token, uint256 _amount) external payable;
}