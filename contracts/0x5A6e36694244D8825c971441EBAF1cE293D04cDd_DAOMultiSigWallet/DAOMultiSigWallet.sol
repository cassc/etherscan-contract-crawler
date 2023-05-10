/**
 *Submitted for verification at Etherscan.io on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DAOMultiSigWallet {
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event Submitted(uint256 indexed transactionId);
    event Executed(uint256 indexed transactionId);
    event OwnerAdded(address indexed newOwner);

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
    }

    address public daoAddress = 0x037D96f143ed76A945Fda4a1b845a0687D9F975E;
    uint256 public required;
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionIdTracker;

    modifier onlyOwner {
        require(msg.sender == daoAddress, "Ownable: caller is not the owner");
        _;
    }

    constructor(uint256 _required) {
        require(_required > 0, "Required threshold must be greater than 0");
        required = _required;
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    function submitTransaction(address _to, uint256 _value) public onlyOwner returns (uint256) {
        transactionIdTracker++;
        transactions[transactionIdTracker] = Transaction({
            to: _to,
            value: _value,
            executed: false
        });
        emit Submitted(transactionIdTracker);

        if (required == 1) {
            execute(transactionIdTracker);
        }

        return transactionIdTracker;
    }

    function execute(uint256 _transactionId) public onlyOwner {
        Transaction storage transaction = transactions[_transactionId];
        require(!transaction.executed, "Transaction already executed");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "Transaction execution failed");

        emit Executed(_transactionId);
    }
}