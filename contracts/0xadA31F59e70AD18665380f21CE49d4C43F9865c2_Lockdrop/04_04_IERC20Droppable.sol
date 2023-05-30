// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.5.0;

interface IERC20Droppable {
    /// @notice When called, the token must mint some amount of new tokens
    /// to `recipient` based on `oldTokenAmount`, and return the amount of
    /// new tokens minted as `newTokenAmount`.
    /// It does not need to make checks about whether old tokens have been locked.
    /// It MUST check that the caller is indeed the Lockdrop contract.
    function drop(uint256 oldTokenAmount, address recipient) external returns (uint256 newTokenAmount);
}