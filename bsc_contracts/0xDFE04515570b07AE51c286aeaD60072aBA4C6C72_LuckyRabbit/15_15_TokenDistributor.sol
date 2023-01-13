// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, type(uint256).max);
    }
}