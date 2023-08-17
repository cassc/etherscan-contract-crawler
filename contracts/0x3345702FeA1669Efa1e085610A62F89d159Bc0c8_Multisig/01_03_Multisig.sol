// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../libs/MemberSet.sol";
import "./Multisigable.sol";

// LightLink 2023
contract Multisig is Multisigable {
  using MemberSet for MemberSet.Record;

  struct Transaction {
    bool executed;
    address target;
    bytes data;
    uint256 value;
    uint256 numConfirmations;
  }

  // variables
  MemberSet.Record internal members;
  // mapping from tx index => owner => bool
  mapping(uint256 => mapping(address => bool)) public isConfirmed;
  Transaction[] public transactions;

  event SubmitTransaction(uint256 indexed txIndex, address indexed account, uint256 value, bytes data);
  event ConfirmTransaction(uint256 indexed txIndex, address indexed owner);
  event RevokeConfirmation(uint256 indexed txIndex, address indexed owner);
  event ExecuteTransaction(uint256 indexed txIndex, address indexed owner);

  constructor() {
    __Multisigable_init(address(this));
    members.add(0xdE2552948aacb82dCa7a04AffbcB1B8e3C97D590);
    members.add(0x26623571D709862776a0E061617634e6474393F2);
  }

  /** Modifier */
  // verified
  modifier requireOwner() {
    require(members.contains(msg.sender), "Owner required");
    _;
  }

  // verified
  modifier requireTxExists(uint256 _txIndex) {
    require(_txIndex < transactions.length, "Nonexistent tx");
    _;
  }

  modifier requireTxNotExecuted(uint256 _txIndex) {
    require(!transactions[_txIndex].executed, "Tx already executed");
    _;
  }

  /* View */
  // verified
  function isOwner(address _account) public view returns (bool) {
    return members.contains(_account);
  }

  // verified
  function getMembers() public view returns (address[] memory) {
    uint256 size = members.size();
    address[] memory records = new address[](size);

    for (uint256 i = 0; i < size; i++) {
      records[i] = members.at(i);
    }
    return records;
  }

  // verified
  function getMemberByIndex(uint256 _index) public view returns (address) {
    return members.at(_index);
  }

  // verified
  function getTransactionCount() public view returns (uint256) {
    return transactions.length;
  }

  // verified
  function getTransaction(uint256 _idx) public view returns (Transaction memory, bytes4 funcSelector) {
    bytes memory data = transactions[_idx].data;
    assembly {
      funcSelector := mload(add(data, 32))
    }
    return (transactions[_idx], funcSelector);
  }

  // verified
  function getSelector(string calldata _func) public pure returns (bytes4) {
    return bytes4(keccak256(bytes(_func)));
  }

  /* Admins */
  // verified
  function addMember(address _account) public virtual requireMultisig {
    members.add(_account);
  }

  // verified
  function removeMember(address _account) public virtual requireMultisig {
    require(members.size() > 1, "Cannot remove last member");
    members.remove(_account);
  }

  // verified
  function submitTransaction(address _target, uint256 _value, bytes calldata _data) public requireOwner {
    _beforeAddTransaction(_data);

    uint256 txIndex = transactions.length;

    transactions.push(Transaction({ executed: false, target: _target, data: _data, value: _value, numConfirmations: 0 }));

    confirmTransaction(txIndex);

    emit SubmitTransaction(txIndex, msg.sender, _value, _data);
  }

  // verified
  function confirmTransaction(uint256 _txIndex) public requireOwner requireTxExists(_txIndex) requireTxNotExecuted(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];

    require(!isConfirmed[_txIndex][msg.sender], "Already confirmed");

    transaction.numConfirmations += 1;
    isConfirmed[_txIndex][msg.sender] = true;

    emit ConfirmTransaction(_txIndex, msg.sender);
  }

  // verified
  function executeTransaction(uint256 _txIndex) public requireOwner requireTxExists(_txIndex) requireTxNotExecuted(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];
    uint256 numConfirmationsRequired = members.size() / 2 + 1;

    require(transaction.numConfirmations >= numConfirmationsRequired, "Confirmations required");

    transaction.executed = true;

    (bool success, ) = transaction.target.call{ value: transaction.value }(transaction.data);
    require(success, "Tx failed");

    emit ExecuteTransaction(_txIndex, msg.sender);
  }

  // verified
  function revokeConfirmation(uint256 _txIndex) public requireOwner requireTxExists(_txIndex) requireTxNotExecuted(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];

    require(isConfirmed[_txIndex][msg.sender], "Confirmation required");

    transaction.numConfirmations -= 1;
    isConfirmed[_txIndex][msg.sender] = false;

    emit RevokeConfirmation(_txIndex, msg.sender);
  }

  /* Internal */
  // verified
  function _beforeAddTransaction(bytes calldata _data) internal pure virtual {
    // bytes4 funcSelector = bytes4(_data[:4]);
  }
}