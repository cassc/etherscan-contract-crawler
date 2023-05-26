/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
contract EthRefund {
    address payable public owner;
    uint256 public airdropAmount;
    uint256 public totalRecipients;

    mapping(uint256 => address payable) public recipients;

    event AirdropComplete(uint256 totalRecipients, uint256 amountPerRecipient);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function addRecipient(address payable _recipient) public onlyOwner {
        recipients[totalRecipients] = _recipient;
        totalRecipients++;
    }

    function depositETH() public payable onlyOwner {
        require(msg.value > 0, "Must deposit a positive amount");
        emit Deposit(msg.value);
    }

    function airdrop() public onlyOwner {
        require(totalRecipients > 0, "Must have recipients");
        require(address(this).balance >= airdropAmount, "Not enough Ether to airdrop");

        uint256 amountPerRecipient = airdropAmount / totalRecipients;

        for (uint256 i = 0; i < totalRecipients; i++) {
            recipients[i].transfer(amountPerRecipient);
        }

        emit AirdropComplete(totalRecipients, amountPerRecipient);
    }

    function updateAirdropAmount(uint256 _airdropAmount) public onlyOwner {
        airdropAmount = _airdropAmount;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Not enough Ether to withdraw");
        owner.transfer(_amount);
        emit Withdraw(_amount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}