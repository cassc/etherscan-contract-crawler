// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PlaNFTReward is Ownable {
    event withdrawETH(address owner, uint256 value);
    event withdrawToken(address token, address to, uint256 value);

    constructor() {}

    function withdrawForETH(uint256 value) public onlyOwner {
        require(address(this).balance >= value, "balances not enough!");
        payable(msg.sender).transfer(value);
        emit withdrawETH(msg.sender, value);
    }

    function withdrawForToken(
        address tokenAddr,
        address to,
        uint256 value
    ) public onlyOwner {
        require(
            IERC20(tokenAddr).balanceOf(address(this)) >= value,
            "balances not enough!"
        );
        IERC20(tokenAddr).transfer(to, value);
        emit withdrawToken(tokenAddr, to, value);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external payable {}
}