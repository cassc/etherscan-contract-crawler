/**
 *Submitted for verification on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    uint public minApprovals; // minimum number of required approvals for a transaction
    address[] public owners; // list of owners who can approve transactions
    mapping(address => bool) public isOwner; // mapping to check if an address is an owner
    uint public transactionCount; // counter to keep track of the number of transactions
    
    struct Transaction {
        address payable to;
        uint amount;
        uint approvals;
        bool executed;
        mapping(address => bool) hasApproved;
    }
    
    mapping(uint => Transaction) public transactions; // mapping to store transactions
    
    event TransactionCreated(uint id, address from, address to, uint amount);
    event ApprovalReceived(uint id, address approver);
    event TransactionExecuted(uint id, address executor);
    
    constructor(uint _minApprovals, address[] memory _owners) {
        require(_minApprovals > 0 && _owners.length > 0 && _minApprovals <= _owners.length, "Invalid input");
        minApprovals = _minApprovals;
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0) && !isOwner[owner], "Invalid owner");
            owners.push(owner);
            isOwner[owner] = true;
        }
    }
    
    function createTransaction(address payable _to, uint _amount) public onlyOwners {
        require(_to != address(0), "Invalid address");
        uint id = transactionCount++;
        Transaction storage transaction = transactions[id];
        transaction.to = _to;
        transaction.amount = _amount;
        transaction.approvals = 0;
        transaction.executed = false;
        emit TransactionCreated(id, msg.sender, _to, _amount);
    }
    
    function approveTransaction(uint _id) public onlyOwners {
        Transaction storage transaction = transactions[_id];
        require(!transaction.executed && !transaction.hasApproved[msg.sender], "Invalid transaction");
        transaction.hasApproved[msg.sender] = true;
        transaction.approvals++;
        emit ApprovalReceived(_id, msg.sender);
        if (transaction.approvals >= minApprovals) {
            executeTransaction(_id);
        }
    }
    
    function executeTransaction(uint _id) public onlyOwners {
        Transaction storage transaction = transactions[_id];
        require(!transaction.executed && transaction.approvals >= minApprovals, "Invalid transaction");
        transaction.executed = true;
        transaction.to.transfer(transaction.amount);
        emit TransactionExecuted(_id, msg.sender);
    }
    
    modifier onlyOwners {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
}