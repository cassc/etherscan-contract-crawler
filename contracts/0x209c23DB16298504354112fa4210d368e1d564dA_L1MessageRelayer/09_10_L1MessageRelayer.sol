// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@arbitrum/nitro-contracts/src/bridge/IInbox.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./L2MessageExecutor.sol";

contract L1MessageRelayer is Ownable {
  /// @notice Address of the governance TimeLock contract.
  address public timeLock;

  /// @notice Address of arbitrum's L1 inbox contract.
  IInbox public inbox;

  /// @notice Emitted when a retryable ticket is created for relaying L1 message to L2.
  event RetryableTicketCreated(uint256 indexed ticketId);

  /// @notice Throws if called by any account other than the timeLock contract.
  modifier onlyTimeLock() {
    require(
      msg.sender == timeLock,
      "L1MessageRelayer::onlyTimeLock: Unauthorized message sender"
    );
    _;
  }

  constructor(address _timeLock, address _inbox) {
    require(_timeLock != address(0), "_timeLock can't the zero address");
    require(_inbox != address(0), "_inbox can't the zero address");
    timeLock = _timeLock;
    inbox = IInbox(_inbox);
  }

  /// @notice renounceOwnership has been disabled so that the contract is never left without a onwer
  /// @inheritdoc Ownable
  function renounceOwnership() public override onlyOwner {
    revert("function disabled");
  }

  /**
   * @notice sends message received from timeLock to L2MessageExecutorProxy.
   * @param target address of the target contract on arbitrum.
   * @param payLoad message calldata that will be executed by l2MessageExecutorProxy.
   * @param maxSubmissionCost same as maxSubmissionCost parameter of inbox.createRetryableTicket
   * @param maxGas same as maxGas parameter of inbox.createRetryableTicket
   * @param gasPriceBid same as gasPriceBid parameter of inbox.createRetryableTicket
   **/
  function relayMessage(
    address target,
    bytes memory payLoad,
    uint256 maxSubmissionCost,
    uint256 maxGas,
    uint256 gasPriceBid
  ) external payable onlyTimeLock returns (uint256) {
    require(maxGas != 1, "maxGas can't be 1");
    require(gasPriceBid != 1, "gasPriceBid can't be 1");
    uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
      target,
      0,
      maxSubmissionCost,
      msg.sender,
      msg.sender,
      maxGas,
      gasPriceBid,
      payLoad
    );
    emit RetryableTicketCreated(ticketID);
    return ticketID;
  }
}