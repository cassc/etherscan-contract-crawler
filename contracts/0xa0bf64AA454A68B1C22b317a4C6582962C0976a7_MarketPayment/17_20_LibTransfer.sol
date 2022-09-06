// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library LibTransfer {
    function transferEth(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "transfer failed");
    }
}