// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Crowdsale is Ownable {
    uint256 private constant MIN_DEPOSIT = 1 * 10 ** 18;
    uint256 private constant MAX_DEPOSIT = 2 * 10 ** 18;

    bool private saleEnded;

    event Deposit(address indexed from, uint256 amount);

    function finishSale() external onlyOwner {
        saleEnded = true;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function contribute() external payable {
        require(!saleEnded, "Sale closed");

        uint256 amount = msg.value;
        require(amount >= MIN_DEPOSIT && amount <= MAX_DEPOSIT, "Invalid amount");

        payable(owner()).transfer(amount);

        emit Deposit(msg.sender, amount);
    }

}