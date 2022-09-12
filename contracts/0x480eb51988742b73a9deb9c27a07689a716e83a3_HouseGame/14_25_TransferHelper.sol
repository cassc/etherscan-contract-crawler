// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library TransferHelper {
    function safeTransfer(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: TRANSFER_FAILED");
    }
}