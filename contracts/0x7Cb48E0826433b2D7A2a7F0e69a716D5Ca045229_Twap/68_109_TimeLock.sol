// SPDX-License-Identifier: BSD-3-Clause
// Copyright 2020 Compound Labs, Inc.

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

contract TimeLock {
  using SafeMath for uint256;

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  uint256 public constant GRACE_PERIOD = 14 days;
  uint256 public constant MINIMUM_DELAY = 2 days;
  uint256 public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint256 public delay;

  mapping(bytes32 => bool) public queuedTransactions;

  constructor(address admin_, uint256 delay_) public {
    require(
      delay_ >= MINIMUM_DELAY,
      "TimeLock::constructor: Delay must exceed minimum delay."
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "TimeLock::constructor: Delay must not exceed maximum delay."
    );

    admin = admin_;
    delay = delay_;
  }

  fallback() external {}

  function setDelay(uint256 delay_) public {
    require(
      msg.sender == address(this),
      "TimeLock::setDelay: Call must come from TimeLock."
    );
    require(
      delay_ >= MINIMUM_DELAY,
      "TimeLock::setDelay: Delay must exceed minimum delay."
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "TimeLock::setDelay: Delay must not exceed maximum delay."
    );
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public {
    require(
      msg.sender == pendingAdmin,
      "TimeLock::acceptAdmin: Call must come from pendingAdmin."
    );
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    require(
      msg.sender == address(this),
      "TimeLock::setPendingAdmin: Call must come from TimeLock."
    );
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public returns (bytes32) {
    require(
      msg.sender == admin,
      "TimeLock::queueTransaction: Call must come from admin."
    );
    require(
      eta >= getBlockTimestamp().add(delay),
      "TimeLock::queueTransaction: Estimated execution block must satisfy delay."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public {
    require(
      msg.sender == admin,
      "TimeLock::cancelTransaction: Call must come from admin."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public payable returns (bytes memory) {
    require(
      msg.sender == admin,
      "TimeLock::executeTransaction: Call must come from admin."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash],
      "TimeLock::executeTransaction: Transaction hasn't been queued."
    );
    require(
      getBlockTimestamp() >= eta,
      "TimeLock::executeTransaction: Transaction hasn't surpassed time lock."
    );
    require(
      getBlockTimestamp() <= eta.add(GRACE_PERIOD),
      "TimeLock::executeTransaction: Transaction is stale."
    );

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) =
      target.call{value: value}(callData);
    require(
      success,
      "TimeLock::executeTransaction: Transaction execution reverted."
    );

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}