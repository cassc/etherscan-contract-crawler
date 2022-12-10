/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IPrizePool {
    /// @notice Deposit assets into the Prize Pool in exchange for tokens
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    function depositTo(address to, uint256 amount) external;

    /// @notice Withdraw assets from the Prize Pool instantly.  A fairness fee may be charged for an early exit.
    /// @param from The address to redeem tokens from.
    /// @param amount The amount of tokens to redeem for assets.
    /// @return The actual amount withdrawn
    function withdrawFrom(address from, uint256 amount)
        external
        returns (uint256);

    /**
     * @notice Read ticket variable
     */
    function getTicket() external view returns (address);
}