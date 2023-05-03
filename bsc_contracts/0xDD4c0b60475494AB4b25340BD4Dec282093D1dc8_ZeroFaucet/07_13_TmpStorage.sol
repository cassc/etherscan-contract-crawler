//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TmpStorage {
    constructor (address token) {
        IERC20(token).approve(msg.sender, type(uint).max);
    }
}