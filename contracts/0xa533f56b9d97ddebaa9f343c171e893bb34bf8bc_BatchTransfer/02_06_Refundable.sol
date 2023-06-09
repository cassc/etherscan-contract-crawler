// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Refundable is Ownable {
    using SafeERC20 for IERC20;

    event RefundETH(address indexed owner, address indexed payee, uint256 amount);
    event RefundToken(address indexed owner, address indexed payee, address indexed token, uint256 amount);

    constructor(address owner_) payable Ownable(owner_) {}

    function refundETH(address payable payee, uint256 amount) public onlyOwner {
        require(payee != address(0), "Payee is 0x0");
        payee.transfer(amount);
        emit RefundETH(owner(), payee, amount);
    }

    function refundETHAll(address payable payee) public onlyOwner {
        refundETH(payee, address(this).balance);
    }

    function refundToken(
        address tokenContract,
        address payee,
        uint256 amount
    ) public onlyOwner {
        require(payee != address(0), "Payee is 0x0");

        IERC20 token = IERC20(tokenContract);
        // safeTransfer is required
        token.safeTransfer(payee, amount);
        emit RefundToken(owner(), payee, tokenContract, amount);
    }

    function refundTokenAll(address tokenContract, address payee) public onlyOwner {
        uint256 balance = IERC20(tokenContract).balanceOf(address(this));
        refundToken(tokenContract, payee, balance);
    }
}