// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/BaseStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    /// Adds a lender to the pool after required off-chain background checking
    function addApprovedLender(address lender) external;

    /// Stops the pool. This stops all money moving in or out of the pool.
    function disablePool() external;

    /// Enables the pool to operate
    function enablePool() external;

    /// Removes a lender from the pool.
    function removeApprovedLender(address lender) external;

    /// Sets the poolConfig for the pool
    function setPoolConfig(address poolConfigAddr) external;

    /// Returns if an account has been approved to contribute to the pool.
    function isApprovedLender(address account) external view returns (bool);

    /// Returns if the pool is on or not
    function isPoolOn() external view returns (bool status);

    /// Returns the last time when the account has contributed to the pool as an LP
    function lastDepositTime(address account) external view returns (uint256);

    /// Returns the pool config associated the pool
    function poolConfig() external view returns (address);

    /// Gets the total pool value right now
    function totalPoolValue() external view returns (uint256);
}