// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./IFRPVault.sol";

/// @title Fixed rate product vault harvesting interface
/// @notice Describes functions for harvesting logic
interface IFRPHarvester {
    /// @notice Exchanges all the available assets into the highest yielding maturity
    /// @param _maxDepositedAmount Max amount of asset to deposit to Notional
    function harvest(uint _maxDepositedAmount) external;

    /// @notice Time required to pass between two harvest events
    /// @return Returns timeout
    function TIMEOUT() external view returns (uint);

    /// @notice Timestamp of last harvest
    /// @return Returns timestamp of last harvest
    function lastHarvest() external view returns (uint96);

    /// @notice Check if can harvest based on time passed
    /// @return Returns true if can harvest
    function canHarvest() external view returns (bool);

    /// @notice fetches the latest 3 and 6 month active markets from Notional and sorts them based on oracle rate
    /// @return lowestYieldMarket lowest yield market
    /// @return highestYieldMarket highest yield market
    function sortMarketsByOracleRate()
        external
        view
        returns (IFRPVault.NotionalMarket memory lowestYieldMarket, IFRPVault.NotionalMarket memory highestYieldMarket);
}