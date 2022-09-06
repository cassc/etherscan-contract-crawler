//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomPaymentSplitter is PaymentSplitter, Ownable {
    uint256 public payeesLength;

    constructor(address[] memory shareholders_, uint256[] memory shares_) PaymentSplitter(shareholders_, shares_) {
        payeesLength = shareholders_.length;
    }

    function releaseAll() external {
        for(uint256 i; i < payeesLength;) {
            address toPay = payee(i);
            release(payable(toPay));
            unchecked {
                i++;
            }
        }
    }

    function releaseAll(IERC20 token) external {
        for(uint256 i; i < payeesLength;) {
            address toPay = payee(i);
            release(token, toPay);
            unchecked {
                i++;
            }
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdraw(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transferFrom(address(this), msg.sender, balance);
    }
}