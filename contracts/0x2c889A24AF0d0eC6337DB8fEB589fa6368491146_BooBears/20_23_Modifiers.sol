// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {BaseErrorCodes} from "ErrorCodes.sol";

abstract contract Modifiers is BaseErrorCodes {
    /**
     * @dev A modifier that verifies that the correct amount of Ether has been recieved prior to executing
     * the function is it applied to.
     */

    modifier requireTrue(bool x, string memory errMsg) {
        require(x, errMsg);
        _;
    }

    modifier requireFalse(bool x, string memory errMsg) {
        require(!x, errMsg);
        _;
    }

    modifier costs(uint16 num, uint256 price) {
        require(msg.value >= price * num, kErrInsufficientFunds);
        _;
    }
}