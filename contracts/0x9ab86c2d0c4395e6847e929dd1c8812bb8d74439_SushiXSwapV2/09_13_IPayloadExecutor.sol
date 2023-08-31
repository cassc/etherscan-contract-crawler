// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

interface IPayloadExecutor {
    function onPayloadReceive(bytes memory _data) external;
}