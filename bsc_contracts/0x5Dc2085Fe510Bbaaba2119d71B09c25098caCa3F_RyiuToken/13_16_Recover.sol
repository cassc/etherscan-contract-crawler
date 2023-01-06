// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Recover is Ownable {
    event TokenRecovered(address indexed token, uint256 amount);

    function recoverTokens(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");

        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            require(IERC20(token).transfer(msg.sender, amount));
        }

        emit TokenRecovered(token, amount);
    }
}