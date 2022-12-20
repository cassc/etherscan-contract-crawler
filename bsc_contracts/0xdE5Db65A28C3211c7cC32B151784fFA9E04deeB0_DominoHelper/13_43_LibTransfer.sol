// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library LibTransfer {

    event transfer(uint value);
    function transferEth(address to, uint value) internal {
        emit transfer(value);
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed");
    }
}