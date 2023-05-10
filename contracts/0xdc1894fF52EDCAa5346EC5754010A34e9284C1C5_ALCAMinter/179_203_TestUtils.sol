// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

contract TestUtils {
    receive() external payable {}

    function payUnpayable(address unpayable) public {
        selfdestruct(payable(unpayable));
    }
}