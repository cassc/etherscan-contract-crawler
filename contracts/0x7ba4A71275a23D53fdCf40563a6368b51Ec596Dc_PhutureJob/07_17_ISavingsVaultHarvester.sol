// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./ISavingsVault.sol";

/// @title Savings vault harvesting interface
/// @notice Describes functions for harvesting logic
interface ISavingsVaultHarvester {
    /// @notice Exchanges all the available assets into the highest yielding maturity
    /// @param _maxDepositedAmount Max amount of asset to deposit to Notional
    function harvest(uint _maxDepositedAmount) external;

    /// @notice Sets timeout for harvesting
    /// @param _timeout Time between two harvests
    function setTimeout(uint32 _timeout) external;

    /// @notice Time required to pass between two harvest events
    /// @return Returns timeout
    function timeout() external view returns (uint32);

    /// @notice fetches the latest 3 and 6 month active markets from Notional and sorts them based on oracle rate
    /// @return lowestYieldMarket lowest yield market
    /// @return highestYieldMarket highest yield market
    function sortMarketsByOracleRate()
        external
        view
        returns (
            ISavingsVault.NotionalMarket memory lowestYieldMarket,
            ISavingsVault.NotionalMarket memory highestYieldMarket
        );
}