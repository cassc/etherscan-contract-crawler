// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YakuzaDeposit is Ownable {

    // Default: Tempura Address
    address public tokenAddress = 0xe2cBC2cF840F9889Eb51b8BB06d4090b8F8e42Be;

    // Default: Dead Address
    address public depositDestination = 0x000000000000000000000000000000000000dEaD;

    // User Total Tokens Deposited
    mapping(address => uint) public userTokensDeposited;

    bool public depositsEnabled = false;

    function depositTokens(uint _depositAmount) external {
        IERC20 token = IERC20(tokenAddress);

        require(depositsEnabled, "Deposits are not currently available"); 
        require(token.balanceOf(msg.sender) > _depositAmount, "You do not have enough tokens to deposit this amount"); 

        token.transferFrom(msg.sender, depositDestination, _depositAmount);
        userTokensDeposited[msg.sender] += _depositAmount;
    }

    function withdrawContractTokens(address _withdrawalToken) public onlyOwner {
        IERC20 token = IERC20(_withdrawalToken);

        token.transferFrom(address(this), msg.sender, token.balanceOf(msg.sender));
    }

    function setDepositStatus(bool _value) public onlyOwner {
        depositsEnabled = _value;
    }

    function setTokenAddress(address _address) public onlyOwner {
        tokenAddress = _address;
    }

    function setDestination(address _dest) public onlyOwner {
        depositDestination = _dest;
    }
}