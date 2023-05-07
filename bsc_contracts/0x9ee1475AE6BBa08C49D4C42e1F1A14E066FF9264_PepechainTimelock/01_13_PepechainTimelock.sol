// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PepechainTimelock is TimelockController {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin)
    {}
    
    function receiveAirdropTokens(IERC20 token, uint256 amount) external onlyRole(EXECUTOR_ROLE) {
        require(token.balanceOf(address(this)) >= amount, "PepechainTimelock: Not enough tokens available");
        token.transfer(msg.sender, amount);
    }
}