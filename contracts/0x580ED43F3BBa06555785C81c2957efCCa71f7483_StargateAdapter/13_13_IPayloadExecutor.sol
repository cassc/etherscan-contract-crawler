// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

interface IPayloadExecutor {
    /// @notice Execute a payload
    /// @param _data The data to pass to payload executor
    function onPayloadReceive(bytes memory _data) external payable;
}