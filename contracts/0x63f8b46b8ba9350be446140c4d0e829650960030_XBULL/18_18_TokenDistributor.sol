// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenDistributor {
    constructor(address token) {
        ERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}