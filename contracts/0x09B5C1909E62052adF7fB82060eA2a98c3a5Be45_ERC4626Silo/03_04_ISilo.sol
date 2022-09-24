// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISilo {
    /// @notice A descriptive name for the silo (ex: Compound USDC Silo)
    function name() external view returns (string memory);

    /// @notice A place to update the silo's internal state
    /// @dev After this has been called, balances reported by `balanceOf` MUST be correct
    function poke() external;

    /// @notice Deposits `amount` of the underlying token
    function deposit(uint256 amount) external;

    /// @notice Withdraws EXACTLY `amount` of the underlying token
    function withdraw(uint256 amount) external;

    /// @notice Reports how much of the underlying token `account` has stored
    /// @dev Must never overestimate `balance`. Should give the exact, correct value after `poke` is called
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice Whether the given token is irrelevant to the silo's strategy (`shouldAllow = true`) or
     * is required for proper management (`shouldAllow = false`). ex: Compound silos shouldn't allow
     * removal of cTokens, but the may allow removal of COMP rewards.
     * @dev Removed tokens are used to help incentivize rebalances for the Blend vault that uses the silo. So
     * if you want something like COMP rewards to go to Blend *users* instead, you'd have to implement a
     * trading function as part of `poke()` to convert COMP to the underlying token.
     */
    function shouldAllowRemovalOf(address token) external view returns (bool shouldAllow);
}