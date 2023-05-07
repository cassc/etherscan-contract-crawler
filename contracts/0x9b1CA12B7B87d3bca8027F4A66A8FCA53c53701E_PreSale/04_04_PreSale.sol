// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

contract PreSale is Ownable {
    using SafeMath for uint256;

    address public tokenAddress;
    address payable private seller;
    uint256 public tokenPrice = 1000000000;
    uint256 public tokensSold;

    uint256 public startTime;
    uint256 public endTime;

    event Sold(address buyer, uint256 amount);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        seller = payable(msg.sender);
        startTime = block.timestamp;
        endTime = block.timestamp + 24 hours;
    }

    function buyToken() public payable {
        require(block.timestamp <= endTime, "Presale has ended");
        uint256 _numberOfTokens = msg.value * tokenPrice;
        IERC20 token = IERC20(tokenAddress);
        uint256 allowance = token.allowance(seller, address(this));
        require(allowance >= _numberOfTokens);
        uint256 balance = token.balanceOf(seller);
        require(balance >= _numberOfTokens);
        require(token.transferFrom(seller, msg.sender, _numberOfTokens));
        tokensSold += _numberOfTokens;
        emit Sold(msg.sender, _numberOfTokens);
    }

    //withdraw found function
    function withdrawFund() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}