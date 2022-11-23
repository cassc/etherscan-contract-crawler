// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

abstract contract NativeReceiver {
    receive() external payable {} // solhint-disable-line no-empty-blocks
}