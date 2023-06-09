// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";

/** @title An IArbitrator implemetation for testing purposes.
 *  @dev DON'T USE ON PRODUCTION.
 */
contract Arbitrator is IArbitrator {
  address public governor = msg.sender;
  uint256 internal arbitrationPrice = 1_000_000_000_000_000_000;

  struct Dispute {
    IArbitrable arbitrated;
    uint256 appealDeadline;
    uint256 numberOfRulingOptions;
    uint256 ruling;
    DisputeStatus status;
  }

  modifier onlyGovernor() {
    require(msg.sender == governor, "Can only be called by the governor.");
    _;
  }

  Dispute[] public disputes;

  function setArbitrationPrice(uint256 _arbitrationPrice) external onlyGovernor {
    arbitrationPrice = _arbitrationPrice;
  }

  function arbitrationCost(bytes memory) public view override returns (uint256 fee) {
    return arbitrationPrice;
  }

  function appealCost(uint256, bytes memory) public view override returns (uint256 fee) {
    return arbitrationCost("UNUSED");
  }

  function createDispute(uint256 _choices, bytes memory _extraData) public payable override returns (uint256 disputeID) {
    uint256 arbitrationFee = arbitrationCost(_extraData);
    require(msg.value >= arbitrationFee, "Value is less than required arbitration fee.");
    disputes.push(
      Dispute({
        arbitrated: IArbitrable(msg.sender),
        numberOfRulingOptions: _choices,
        ruling: 0,
        status: DisputeStatus.Waiting,
        appealDeadline: 0
      })
    );
    disputeID = disputes.length - 1;
    emit DisputeCreation(disputeID, IArbitrable(msg.sender));
  }

  function giveRuling(
    uint256 _disputeID,
    uint256 _ruling,
    uint256 _appealWindow
  ) external onlyGovernor {
    Dispute storage dispute = disputes[_disputeID];
    require(_ruling <= dispute.numberOfRulingOptions, "Invalid ruling.");
    require(dispute.status == DisputeStatus.Waiting, "The dispute must be waiting for arbitration.");

    dispute.ruling = _ruling;
    dispute.status = DisputeStatus.Appealable;
    dispute.appealDeadline = block.timestamp + _appealWindow;

    emit AppealPossible(_disputeID, dispute.arbitrated);
  }

  function appeal(uint256 _disputeID, bytes memory _extraData) public payable override {
    Dispute storage dispute = disputes[_disputeID];
    uint256 appealFee = appealCost(_disputeID, _extraData);
    require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
    require(block.timestamp < dispute.appealDeadline, "The appeal must occur before the end of the appeal period.");
    require(msg.value >= appealFee, "Value is less than required appeal fee");

    dispute.appealDeadline = 0;
    dispute.status = DisputeStatus.Waiting;
    emit AppealDecision(_disputeID, IArbitrable(msg.sender));
  }

  function executeRuling(uint256 _disputeID) external {
    Dispute storage dispute = disputes[_disputeID];
    require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
    require(block.timestamp >= dispute.appealDeadline, "The dispute must be executed after its appeal period has ended.");

    dispute.status = DisputeStatus.Solved;
    dispute.arbitrated.rule(_disputeID, dispute.ruling);
  }

  function disputeStatus(uint256 _disputeID) public view override returns (DisputeStatus status) {
    Dispute storage dispute = disputes[_disputeID];
    if (disputes[_disputeID].status == DisputeStatus.Appealable && block.timestamp >= dispute.appealDeadline)
      // If the appeal period is over, consider it solved even if rule has not been called yet.
      return DisputeStatus.Solved;
    else return disputes[_disputeID].status;
  }

  function currentRuling(uint256 _disputeID) public view override returns (uint256 ruling) {
    return disputes[_disputeID].ruling;
  }

  function appealPeriod(uint256 _disputeID) public view override returns (uint256 start, uint256 end) {
    Dispute storage dispute = disputes[_disputeID];
    return (block.timestamp, dispute.appealDeadline);
  }
}