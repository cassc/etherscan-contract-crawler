/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface ILiquidityManagerNFT {
    /// @notice get the last token id
    /// @return the last token id
    function tokenID() external view returns (uint256);
}