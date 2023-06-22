pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KolectivExchange is Ownable, Pausable, ReentrancyGuard {
    using Address for address;

    event Deposit(address indexed account, uint256 amount, uint256 indexed exchangeId);
    event Withdraw(address indexed account, uint256 amount, uint256 indexed exchangeId);
    mapping (uint256 => uint256) private deposits;
    mapping (uint256 => uint256) private withdraws;
    uint256 public reservedBalance;
    uint256 public minDeposit;

    constructor() {
        reservedBalance = 0;
        minDeposit = 0;
    }

    function getDepositBalance(uint256 exchangeId) public view returns (uint256) {
        return deposits[exchangeId];
    }

    function getWithdrawBalance(uint256 exchangeId) public view returns (uint256) {
        return withdraws[exchangeId];
    }

    function deposit(uint256 exchangeId) public payable whenNotPaused {
        require(msg.value > 0, "No value provided to deposit.");
        require(msg.value >= minDeposit, "The minimum amount to deposit has not been met.");
        require(deposits[exchangeId] == 0, "That deposit has already been completed");
        deposits[exchangeId] = msg.value;
        emit Deposit(msg.sender, msg.value, exchangeId);
    }

    // --------- Only owner functionality below here --------------------------------------------------------------
    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function withdraw(address payable account, uint256 amount, uint256 exchangeId) public onlyOwner nonReentrant whenNotPaused {
        require(amount > 0, "No value provided to withdraw.");
        require(withdraws[exchangeId] == 0, "That withdraw has already been completed");
        require(address(this).balance - amount >= reservedBalance, "That withdraw will use reserved funds.");
        withdraws[exchangeId] = amount;
        sendValue(account, amount);
        emit Withdraw(account, amount, exchangeId);
    }

    function withdrawOwner(address payable account, uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "No value provided to withdraw.");
        sendValue(account, amount);
        emit Withdraw(account, amount, 0);
    }

    function withdrawOwnerAll(address payable account) public onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        sendValue(account, amount);
        emit Withdraw(account, amount, 0);
    }

    function getReservedBalance() public view returns (uint256) {
        return reservedBalance;
    }

    function setReservedBalance(uint256 balance) public onlyOwner returns (uint256) {
        reservedBalance = balance;
        return reservedBalance;
    }

    function getMinDeposit() public view returns (uint256) {
        return minDeposit;
    }

    function setMinDeposit(uint256 amount) public onlyOwner returns (uint256) {
        minDeposit = amount;
        return minDeposit;
    }

    function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}