// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";

contract A4Bank {

    using SafeERC20 for IERC20;

    event SetStaking(address staking, bool status);

    IERC20 private _token;
    mapping(address => bool) public isStaking;

    constructor (IERC20 token, address[] memory stakings) {
        _token = token;
        for (uint i = 0; i < stakings.length; i++) {
            isStaking[stakings[i]] = true;
        }
    }

    function transferTo(address to, uint256 amount) external {
        require(isStaking[msg.sender], "A4Bank: only staking contracts");

        _token.safeTransfer(to, amount);
    }

    function setStaking(address staking, bool status) external {
        require(isStaking[msg.sender], "A4Bank: only staking contracts");

        isStaking[staking] = status;

        emit SetStaking(staking, status);
    }

}