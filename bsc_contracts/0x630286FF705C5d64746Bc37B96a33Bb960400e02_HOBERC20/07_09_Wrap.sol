// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wrap {
    address private immutable owner;
    IERC20 private immutable token;

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    function claim() external {
        if (msg.sender != owner) revert();
        token.transfer(owner, token.balanceOf(address(this)));
    }
}