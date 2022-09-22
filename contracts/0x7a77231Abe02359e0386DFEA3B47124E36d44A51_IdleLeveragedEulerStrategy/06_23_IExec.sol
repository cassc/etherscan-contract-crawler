// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./IRiskManager.sol";

interface IExec {
    /// @notice Compute aggregate liquidity for an account
    /// @param account User address
    /// @return status Aggregate liquidity (sum of all entered assets)
    function liquidity(address account) external view returns (IRiskManager.LiquidityStatus memory status);
}