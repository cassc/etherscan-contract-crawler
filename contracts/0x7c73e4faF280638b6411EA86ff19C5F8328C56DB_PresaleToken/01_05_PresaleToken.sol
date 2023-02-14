// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PresaleToken is Ownable, ReentrancyGuard {
    IERC20 public token;
    address public from;
    uint256 private balance;
    uint256 public conversionRate;

    event Withdraw(address indexed wallet, uint256 amount, uint256 date);
    event Transfer(address indexed to, uint256 value);

    constructor(address _token, address _from, uint256 _conversionRate) {
        token = IERC20(_token);
        from = _from;
        conversionRate = _conversionRate;
    }

    function changeFromAddress(address _from) public onlyOwner {
        from = _from;
    }

    function changeConversionRate(uint256 _rate) public onlyOwner {
        conversionRate = _rate;
    }

    function checkBalance() public view onlyOwner returns(uint256) {
        return balance;
    }

    function transferTokens() public payable nonReentrant {
        address _to = msg.sender;
        require(_to != address(0), "Non zero address required");
        require(msg.value != 0, "More than 0 eth required");
        balance = balance + msg.value;
        uint256 tokensToSend = msg.value * conversionRate;
        token.transferFrom(from, _to, tokensToSend);
        emit Transfer(_to, tokensToSend);
    }

    function withDrawEth() public onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: balance}("");
        require(os, "Withdraw not Successful!");
        emit Withdraw(msg.sender, balance, block.timestamp);
    }
}