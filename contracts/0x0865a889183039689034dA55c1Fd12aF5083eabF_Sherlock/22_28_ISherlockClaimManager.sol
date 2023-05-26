// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './callbacks/ISherlockClaimManagerCallbackReceiver.sol';
import '../UMAprotocol/OptimisticRequester.sol';
import './IManager.sol';

interface ISherlockClaimManager is IManager, OptimisticRequester {
  // Doesn't allow a new claim to be submitted by a protocol agent if a claim is already active for that protocol
  error ClaimActive();

  // If the current state of a claim does not match the expected state, this error is thrown
  error InvalidState();

  event ClaimCreated(
    uint256 claimID,
    bytes32 indexed protocol,
    uint256 amount,
    address receiver,
    bool previousCoverageUsed
  );

  event CallbackAdded(ISherlockClaimManagerCallbackReceiver callback);

  event CallbackRemoved(ISherlockClaimManagerCallbackReceiver callback);

  event ClaimStatusChanged(uint256 indexed claimID, State previousState, State currentState);

  event ClaimPayout(uint256 claimID, address receiver, uint256 amount);

  event ClaimHalted(uint256 claimID);

  event UMAHORenounced();

  enum State {
    NonExistent, // Claim doesn't exist (this is the default state on creation)
    SpccPending, // Claim is created, SPCC is able to set state to valid
    SpccApproved, // Final state, claim is valid
    SpccDenied, // Claim denied by SPCC, claim can be escalated within 4 weeks
    UmaPriceProposed, // Price is proposed but not escalated
    ReadyToProposeUmaDispute, // Price is proposed, callback received, ready to submit dispute
    UmaDisputeProposed, // Escalation is done, waiting for confirmation
    UmaPending, // Claim is escalated, in case Spcc denied or didn't act within 7 days.
    UmaApproved, // Final state, claim is valid, claim can be enacted after 1 day, umaHaltOperator has 1 day to change to denied
    UmaDenied, // Final state, claim is invalid
    Halted, // UMAHO can halt claim if state is UmaApproved
    Cleaned // Claim is removed by protocol agent
  }

  struct Claim {
    uint256 created;
    uint256 updated;
    address initiator;
    bytes32 protocol;
    uint256 amount;
    address receiver;
    uint32 timestamp;
    State state;
    bytes ancillaryData;
  }

  // requestAndProposePriceFor() --> proposer = sherlockCore (address to receive BOND if UMA denies claim)
  // disputePriceFor() --> disputer = protocolAgent
  // priceSettled will be the the callback that contains the main data

  // Assume BOND = 9600, UMA's final fee = 1500.
  // Claim initiator (Sherlock) has to pay 22.2k to dispute a claim,
  // so we will execute a safeTransferFrom(claimInitiator, address(this), 22.2k).
  // We need to approve the contract 22.2k as it will be transferred from address(this).

  // The 22.2k consists of 2 * (BOND + final fee charged by UMA), as follows:
  // 1. On requestAndProposePriceFor(), the fee will be 10k: 9600 BOND + 1500 UMA's final fee;
  // 2. On disputePriceFor(), the fee will be the same 10k.
  // note that half of the BOND (4800) + UMA's final fee (1500) is "burnt" and sent to UMA

  // UMA's final fee can be changed in the future, which may result in lower or higher required staked amounts for escalating a claim.

  // On settle, either the protocolAgent (dispute success) or sherlockCore (dispute failure)
  // will receive 9600 + 4800 + 1500 = 15900. In addition, the protocolAgent will be entitled to
  // the claimAmount if the dispute is successful/

  // lastClaimID <-- starts with 0, so initial id = 1
  // have claim counter, easy to identify certain claims by their number
  // but use hash(callback.request.propose + callback.timestamp) as the internal UUID to handle the callbacks

  // So SPCC and UMAHO are hardcoded (UMAHO can be renounced)
  // In case these need to be updated, deploy different contract and upgrade it on the sherlock gov side.

  // On price proposed callback --> call disputePriceFor with callbackdata + sherlock.strategyManager() and address(this)

  /// @notice `SHERLOCK_CLAIM` in utf8
  function UMA_IDENTIFIER() external view returns (bytes32);

  function sherlockProtocolClaimsCommittee() external view returns (address);

  /// @notice operator is able to deny approved UMA claims
  function umaHaltOperator() external view returns (address);

  /// @notice gov is able to renounce the role
  function renounceUmaHaltOperator() external;

  function claim(uint256 _claimID) external view returns (Claim memory);

  /// @notice Initiate a claim for a specific protocol as the protocol agent
  /// @param _protocol protocol ID (different from the internal or public claim ID fields)
  /// @param _amount amount of USDC which is being claimed by the protocol
  /// @param _receiver address to receive the amount of USDC being claimed
  /// @param _timestamp timestamp at which the exploit first occurred
  /// @param ancillaryData other data associated with the claim, such as the coverage agreement
  /// @dev The protocol agent that starts a claim will be the protocol agent during the claims lifecycle
  /// @dev Even if the protocol agent role is tranferred during the lifecycle
  function startClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    uint32 _timestamp,
    bytes memory ancillaryData
  ) external;

  function spccApprove(uint256 _claimID) external;

  function spccRefuse(uint256 _claimID) external;

  /// @notice Callable by protocol agent
  /// @param _claimID Public claim ID
  /// @param _amount Bond amount sent by protocol agent
  /// @dev Use hardcoded USDC address
  /// @dev Use hardcoded bond amount
  /// @dev Use hardcoded liveness 7200 (2 hours)
  /// @dev proposedPrice = _amount
  function escalate(uint256 _claimID, uint256 _amount) external;

  /// @notice Execute claim, storage will be removed after
  /// @param _claimID Public ID of the claim
  /// @dev Needs to be SpccApproved or UmaApproved && >UMAHO_TIME
  /// @dev Funds will be pulled from core
  function payoutClaim(uint256 _claimID) external;

  /// @notice UMAHO is able to execute a halt if the state is UmaApproved and state was updated less than UMAHO_TIME ago
  function executeHalt(uint256 _claimID) external;
}