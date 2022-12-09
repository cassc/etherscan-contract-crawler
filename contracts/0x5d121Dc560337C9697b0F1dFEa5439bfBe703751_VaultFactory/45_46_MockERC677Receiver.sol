// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IERC677Receiver} from "../interfaces/IERC20/IERC677Receiver.sol";

contract MockERC677Receiver is IERC677Receiver {
    event OnTransferReceived(address sender, uint256 value, bytes data);

    function onTokenTransfer(
        address sender,
        uint256 value,
        bytes memory data
    ) external returns (bool) {
        emit OnTransferReceived(sender, value, data);
        return true;
    }
}