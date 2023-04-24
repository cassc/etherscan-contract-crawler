// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Recoverable} from "../utils/Recoverable.sol";
import {IWETH} from "../../interfaces/IWETH.sol";


contract SweepingFunds is Recoverable {
    address public immutable MASTER;
    address public immutable COLLECTION;

    constructor(address _master, address _collection) {
        MASTER = _master;
        COLLECTION = _collection;
    }

    receive() external payable {}

    function fundSweep(uint256 price) external {
        require(msg.sender == MASTER, "Only master");
        Address.sendValue(payable(msg.sender), price);
    }

    function closeFunds(address payable receiver, bool destruct) external {
        require(msg.sender == MASTER || msg.sender == owner(), "Not eligible");
        if (destruct) {
            selfdestruct(receiver);
        } else {
            Address.sendValue(receiver, address(this).balance);
        }
    }
}