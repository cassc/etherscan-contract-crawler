// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";

contract TokenDistributor {
    constructor(address token) public {
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}
