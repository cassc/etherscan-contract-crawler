// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenBack is Ownable {
    address token;

    constructor(address tokenAddr) {
        token = tokenAddr;
    }

    function take() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
        selfdestruct(payable(msg.sender));
    }
}