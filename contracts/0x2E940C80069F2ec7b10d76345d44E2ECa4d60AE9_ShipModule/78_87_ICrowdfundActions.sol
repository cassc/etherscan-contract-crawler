// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Actions open during the Crowdfund phase
interface ICrowdfundActions {
    /// @notice Contribute ETH for ship tokens
    /// @return minted The amount of ship tokens minted
    function contribute() external payable returns (uint256 minted);

    /// @notice Check if raise met
    /// @return True if raise was met
    function hasRaiseMet() external view returns (bool);

    /// @notice Check users can still contribute
    /// @return True if closed
    function isRaiseOpen() external view returns (bool);

    /// @notice End the ship raise
    function endRaise() external;
}