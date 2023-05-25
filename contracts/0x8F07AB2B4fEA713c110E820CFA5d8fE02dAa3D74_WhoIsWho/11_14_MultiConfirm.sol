// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract MultiConfirm is Context {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    ///////////////////////////////////////////////
    /// Constants
    //////////////////////////////////////////////

    /// Number of confirmations required
    uint32 public constant NUM_CONFIRMATIONS_REQUIRED = 3;

    ///////////////////////////////////////////////
    /// Storages
    //////////////////////////////////////////////

    /// Transactions array
    Transaction[] public transactions;

    /// Approvers Array
    address[] public approvers;

    // Mapping from tx index => operator => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    /// Mapping from approver to bool
    mapping(address => bool) public isApprover;

    ///////////////////////////////////////////////
    /// Events
    //////////////////////////////////////////////

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);

    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);

    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    ///////////////////////////////////////////////
    /// Constructor
    //////////////////////////////////////////////
    constructor(address[] memory _approvers) {
        require(_approvers.length > 0, "owners required");

        for (uint256 i = 0; i < _approvers.length; i++) {
            address approver = _approvers[i];

            require(approver != address(0), "invalid approver");
            require(!isApprover[approver], "approver not unique");

            isApprover[approver] = true;
            approvers.push(approver);
        }
    }

    ///////////////////////////////////////////////
    /// Modifiers
    //////////////////////////////////////////////
    modifier onlyApprover() {
        require(isApprover[_msgSender()], "not approver");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx doesn't exists");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][_msgSender()], "tx already confirmed");
        _;
    }

    ///////////////////////////////////////////////
    /// Internal Functions
    //////////////////////////////////////////////

    function _submitTransaction(address _to, uint256 _value, bytes memory _data) internal onlyApprover {
        uint256 txIndex = transactions.length;
        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false, numConfirmations: 0}));

        emit SubmitTransaction(_msgSender(), txIndex, _to, _value, _data);
    }

    function _confirmTransaction(
        uint256 _txIndex
    ) internal onlyApprover txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations++;
        isConfirmed[_txIndex][_msgSender()] = true;

        emit ConfirmTransaction(_msgSender(), _txIndex);
    }

    function _revokeConfirmation(uint256 _txIndex) internal onlyApprover txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][_msgSender()], "tx not confirmed");

        transaction.numConfirmations--;
        isConfirmed[_txIndex][_msgSender()] = false;

        emit RevokeConfirmation(_msgSender(), _txIndex);
    }

    function _executeTransaction(uint256 _txIndex) internal onlyApprover txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= NUM_CONFIRMATIONS_REQUIRED, "tx can't execute");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "transfer failed");

        emit ExecuteTransaction(_msgSender(), _txIndex);
    }

    ///////////////////////////////////////////////
    /// View Functions
    //////////////////////////////////////////////

    function getApprovers() public view returns (address[] memory) {
        return approvers;
    }

    function getTransaction(
        uint256 _txIndex
    ) public view returns (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations) {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}