// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "./IPriceProvider.sol";

/// @title Common interface V2 for Silo Price Providers
interface IPriceProviderV2 is IPriceProvider {
    /// @dev for liquidation purposes and for compatibility with naming convention we already using in LiquidationHelper
    /// we have this method to return on-chain provider that can be useful for liquidation
    function getFallbackProvider(address _asset) external view returns (IPriceProvider);

    /// @dev this is info method for LiquidationHelper
    /// @return bool TRUE if provider is off-chain, means it is not a dex
    function offChainProvider() external pure returns (bool);
}