// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    modifier onlyAllowedOperator() virtual {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}