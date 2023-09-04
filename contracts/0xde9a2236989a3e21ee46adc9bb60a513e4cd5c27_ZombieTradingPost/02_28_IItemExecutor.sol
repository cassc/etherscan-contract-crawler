// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IItemExecutor {
    function executeOnTransfer(uint256 itemId) external returns (bool executed);
    function executeAction(uint256 itemId) external returns (bool executed);
}