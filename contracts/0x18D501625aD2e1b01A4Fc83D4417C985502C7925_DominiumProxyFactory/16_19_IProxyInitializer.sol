//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Proxy initialization
interface IProxyInitializer {
    /// @dev Initializes the proxy
    /// @param anticFeeCollector Address that the Antic fees will be sent to
    /// @param anticJoinFeePercentage Antic join fee percentage out of 1000
    /// e.g. 25 -> 25/1000 = 2.5%
    /// @param anticSellFeePercentage Antic sell/receive fee percentage out of 1000
    /// e.g. 25 -> 25/1000 = 2.5%
    /// @param data Proxy initialization data
    function proxyInit(
        address anticFeeCollector,
        uint16 anticJoinFeePercentage,
        uint16 anticSellFeePercentage,
        bytes memory data
    ) external;

    /// @return True, if the proxy is initialized
    function initialized() external view returns (bool);
}