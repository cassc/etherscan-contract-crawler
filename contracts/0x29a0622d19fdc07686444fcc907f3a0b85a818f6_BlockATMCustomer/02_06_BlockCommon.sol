// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BlockCommon {

    using SafeERC20 for IERC20;

    modifier checkAmount(uint256 amount) {
        require(amount > 0, "amount must be greater than zero");
        _; 
    }

    // "transfer token is the zero address"
    modifier checkTokenAddress(address tokenAddress){
        require(tokenAddress != address(0), "transfer token is the zero address");
        _; 
    }

    modifier checkWithdrawAddress(address withdrawAddress){
        require(withdrawAddress != address(0), "withdraw address is the zero address");
        _; 
    }

    
    function transferCommon(address tokenAddress,address to,uint256 amount) internal checkTokenAddress(tokenAddress) checkAmount(amount) returns(uint256) {
        IERC20 erc20 = IERC20(tokenAddress); 
        uint256 beforeAmount = erc20.balanceOf(to);
        erc20.safeTransferFrom(msg.sender, to, amount);
        uint256 afterAmount = erc20.balanceOf(to);
        uint256 finalAmount = afterAmount - beforeAmount;
        require(finalAmount <= amount, "FinalAmount is error");
        return finalAmount;
    }

    function withdrawCommon(address tokenAddress,address withdrawAddress,uint256 amount) internal checkAmount(amount) checkTokenAddress(tokenAddress) checkWithdrawAddress(withdrawAddress) {
        IERC20 erc20 = IERC20(tokenAddress);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance >= amount, "Insufficient balance");
        erc20.safeTransfer(withdrawAddress, amount); 
    }

}