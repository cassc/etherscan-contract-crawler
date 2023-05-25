/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./AccountLocker.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract BatchTransferEnabled is AccountLocker {

    function doBatchTransferWithLock(
        uint256 taskId,
        address[] memory tos,
        uint256[] memory amounts,
        uint256[] memory lockTss
    ) external
      tryExecuteTaskAfterwards(taskId)
    {
        _doBatchTransferWithLock(tos, amounts, lockTss);
    }

    function _batchTransferSingle(address source, address to, uint256 amount) internal virtual;

    function _doBatchTransferWithLock(
        address[] memory tos,
        uint256[] memory amounts,
        uint256[] memory lockTss
    ) private {
        require(_getTaskManager() != address(0), "BatchTransferEnabled: batch transfer source is not set");
        require(tos.length == amounts.length, "BatchTransferEnabled: inputs have incorrect lengths");
        require(tos.length == lockTss.length, "BatchTransferEnabled: inputs have incorrect lengths");
        require(tos.length > 0, "BatchTransferEnabled: empty inputs");
        for (uint256 i = 0; i < tos.length; i++) {
            require(tos[i] != address(0), "BatchTransferEnabled: target with zero address");
            require(tos[i] != _getTaskManager(), "BatchTransferEnabled: invalid target");
            if (amounts[i] > 0) {
                _batchTransferSingle(_getTaskManager(), tos[i], amounts[i]);
            }
            if (lockTss[i] > 0) {
                _updateLockTs(tos[i], lockTss[i]);
            }
        }
    }
}