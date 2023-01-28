// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IERC20.sol";

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}