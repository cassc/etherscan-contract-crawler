// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TestTransfer {

    function transferTo(address to, uint amount) payable public {
        payable(to).transfer(amount);
    }
}