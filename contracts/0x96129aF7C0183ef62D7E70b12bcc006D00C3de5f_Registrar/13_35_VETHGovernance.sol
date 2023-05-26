// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { AdminAgent } from "../access/AdminAgent.sol";
import { VETHYieldRateTreasury } from "../treasury/VETHYieldRateTreasury.sol";
import { VYToken } from "../token/VYToken.sol";
import { VETHRevenueCycleTreasury } from "../exchange/VETHRevenueCycleTreasury.sol";
import { VETHReverseStakingTreasury } from "../VETHReverseStakingTreasury.sol";
import { RegistrarClient } from "../RegistrarClient.sol";

contract VETHGovernance is AdminAgent, RegistrarClient {

  enum VoteOptions {
    YES,
    NO
  }

  enum ProposalType {
    Migration,
    Registrar
  }

  struct MigrationProposal {
    address yieldRateTreasuryDestination;
    address revenueCycleTreasuryDestination;
    address reverseStakingTreasuryDestination;
  }

  struct RegistrarProposal {
    address registrar; // Registrar to add
  }

  struct Proposal {
    ProposalType proposalType;
    uint256 endsAt;
    bool approved;
    MigrationProposal migration;
    RegistrarProposal registrar;
  }

  event StartMigrationProposal(
    uint256 proposalId,
    address yieldRateTreasuryDestination,
    address revenueCycleTreasuryDestination,
    address reverseStakingTreasuryDestination,
    uint256 endsAt
  );
  event StartRegistrarProposal(uint256 proposalId, address registrar, uint256 endsAt);

  VYToken private _vyToken;
  VETHYieldRateTreasury private _vethYRT;
  VETHRevenueCycleTreasury private _vethRevenueCycleTreasury;
  VETHReverseStakingTreasury private _vethReverseStakingTreasury;
  mapping(uint256 => mapping(address => uint256)) private _deposits;
  mapping(uint256 => mapping(VoteOptions => uint256)) private _voteCount;
  mapping(uint256 => Proposal) private _proposals;
  uint256 public votingPeriod;  // In seconds
  uint256 private _proposalNonce = 0;

  event Vote(address account, VoteOptions voteOption, uint256 quantity);

  constructor(
    address registrarAddress,
    uint256 votingPeriod_,
    address[] memory adminAgents
  ) AdminAgent(adminAgents) RegistrarClient(registrarAddress) {
    votingPeriod = votingPeriod_;
  }

  modifier hasMigrationAddresses() {
    require(address(_vethYRT) != address(0), "ETH Treasury address not set");
    require(address(_vethRevenueCycleTreasury) != address(0), "VETHRevenueCycleTreasury address not set");
    require(address(_vethReverseStakingTreasury) != address(0), "VETHReverseStakingTreasury address not set");
    _;
  }

  modifier hasProposal() {
    require(_proposals[_proposalNonce].endsAt > 0, "No proposal");
    _;
  }

  modifier hasProposalById(uint256 proposalId) {
    require(_proposals[proposalId].endsAt > 0, "No proposal");
    _;
  }

  function getCurrentProposal() external view returns (Proposal memory) {
    return _proposals[_proposalNonce];
  }

  function getProposalById(uint256 proposalId) external view returns (Proposal memory) {
    return _proposals[proposalId];
  }

  function getCurrentProposalId() external view returns (uint256) {
    return _proposalNonce;
  }

  function getCurrentYesVotes() external view returns (uint256) {
    return _voteCount[_proposalNonce][VoteOptions.YES];
  }

  function getCurrentNoVotes() external view returns (uint256) {
    return _voteCount[_proposalNonce][VoteOptions.NO];
  }

  function getYesVotesById(uint256 proposalId) external view returns (uint256) {
    return _voteCount[proposalId][VoteOptions.YES];
  }

  function getNoVotesById(uint256 proposalId) external view returns (uint256) {
    return _voteCount[proposalId][VoteOptions.NO];
  }

  function getCurrentDepositedVY(address voter) external view returns (uint256) {
    return _deposits[_proposalNonce][voter];
  }

  function getDepositedVYById(uint256 proposalId, address voter) external view returns (uint256) {
    return _deposits[proposalId][voter];
  }

  function hasCurrentProposalEnded() public view hasProposal returns (bool) {
    return block.timestamp > _proposals[_proposalNonce].endsAt;
  }

  function hasProposalEndedById(uint256 proposalId) external view hasProposalById(proposalId) returns (bool) {
    return block.timestamp > _proposals[proposalId].endsAt;
  }

  function voteYes(uint256 quantity) external {
    _vote(VoteOptions.YES, quantity);
  }

  function voteNo(uint256 quantity) external {
    _vote(VoteOptions.NO, quantity);
  }

  function _vote(VoteOptions voteOption, uint256 quantity) private hasProposal {
    require(block.timestamp < _proposals[_proposalNonce].endsAt, "Proposal already ended");
    require(_deposits[_proposalNonce][_msgSender()] == 0, "Already voted");
    require(_vyToken.allowance(_msgSender(), address(this)) >= quantity, "Insufficient VY allowance");
    require(_vyToken.balanceOf(_msgSender()) >= quantity, "Insufficient VY balance");

    _deposits[_proposalNonce][_msgSender()] += quantity;
    _voteCount[_proposalNonce][voteOption] += quantity;
    _vyToken.transferFrom(_msgSender(), address(this), quantity);

    emit Vote(_msgSender(), voteOption, quantity);
  }

  function startMigrationProposal(
    address yieldRateTreasuryDestination,
    address revenueCycleTreasuryDestination,
    address reverseStakingTreasuryDestination
  ) external onlyAdminAgents {
    // Prevent funds locked up in zero address
    require(
      yieldRateTreasuryDestination != address(0) &&
        revenueCycleTreasuryDestination != address(0) &&
        reverseStakingTreasuryDestination != address(0),
      "Invalid address"
    );

    // Should only allow starting new proposal after current one is expired
    // Note: starting first proposal where _proposalNonce is 0 should not require expiration condition
    require(block.timestamp > _proposals[_proposalNonce].endsAt || _proposalNonce == 0, "Proposal still ongoing");

    uint256 endsAt = block.timestamp + votingPeriod;

    // Create new proposal and increment nounce
    _proposals[++_proposalNonce] = Proposal(
      ProposalType.Migration,
      endsAt,
      false,
      MigrationProposal(yieldRateTreasuryDestination, revenueCycleTreasuryDestination, reverseStakingTreasuryDestination),
      RegistrarProposal(address(0))
    );

    // Emit event
    emit StartMigrationProposal(
      _proposalNonce,
      yieldRateTreasuryDestination,
      revenueCycleTreasuryDestination,
      reverseStakingTreasuryDestination,
      endsAt
    );
  }

  function executeMigrationProposal() external hasMigrationAddresses hasProposal onlyAdminAgents {
    require(hasCurrentProposalEnded(), "Proposal still ongoing");
    require(_proposals[_proposalNonce].proposalType == ProposalType.Migration, "Invalid proposal");
    require(_voteCount[_proposalNonce][VoteOptions.YES] >= _voteCount[_proposalNonce][VoteOptions.NO], "Proposal not passed");

    _proposals[_proposalNonce].approved = true;

    // execute VETHYieldRateTreasury migration
    _vethYRT.setMigration(_proposals[_proposalNonce].migration.yieldRateTreasuryDestination);

    // execute VETHRevenueCycleTreasury migration
    _vethRevenueCycleTreasury.setMigration(_proposals[_proposalNonce].migration.revenueCycleTreasuryDestination);

    // execute VETHReverseStakingTreasury migration
    _vethReverseStakingTreasury.setMigration(_proposals[_proposalNonce].migration.reverseStakingTreasuryDestination);
  }

  function startRegistrarProposal(address registrar) external onlyAdminAgents {
    // Prevent funds locked up in zero address
    require(registrar != address(0), "Invalid address");

    // Should only allow starting new proposal after current one is expired
    // Note: starting first proposal where _proposalNonce is 0 should not require expiration condition
    require(block.timestamp > _proposals[_proposalNonce].endsAt || _proposalNonce == 0, "Proposal still ongoing");

    uint256 endsAt = block.timestamp + votingPeriod;

    _proposals[++_proposalNonce] = Proposal(
      ProposalType.Registrar,
      endsAt,
      false,
      MigrationProposal(address(0), address(0), address(0)),
      RegistrarProposal(registrar)
    );

    // Emit event
    emit StartRegistrarProposal(
      _proposalNonce,
      registrar,
      endsAt
    );
  }

  function executeRegistrarProposal() external hasProposal onlyAdminAgents {
    require(hasCurrentProposalEnded(), "Proposal still ongoing");
    require(_proposals[_proposalNonce].proposalType == ProposalType.Registrar, "Invalid proposal");
    require(_voteCount[_proposalNonce][VoteOptions.YES] >= _voteCount[_proposalNonce][VoteOptions.NO], "Proposal not passed");

    _proposals[_proposalNonce].approved = true;

    // Register new Registrar with VYToken
    _vyToken.setRegistrar(_registrar.getEcosystemId(), _proposalNonce);
  }

  // Withdraw from current proposal
  function withdrawDepositedVY() external {
    _withdraw(_proposalNonce);
  }

  // Withdraw by proposal id
  function withdrawDepositedVYById(uint256 proposalId) external {
    _withdraw(proposalId);
  }

  // Withdraw from all proposals
  function withdrawAllDepositedVY() external hasProposal {
    // Check if current proposal is still ongoing - to continue current proposal has to end first
    require(hasCurrentProposalEnded(), "Proposal still ongoing");

    // When _withdraw is called this variable will be false
    bool nothingToWithdraw = true;

    // Loop to withdraw proposals that have deposits
    for (uint proposalId = 1; proposalId <= _proposalNonce; proposalId++) {
      if (_deposits[proposalId][_msgSender()] > 0) { // Check if there is anything to withdraw
        nothingToWithdraw = false;
        _withdraw(proposalId);
      }
    }

    // If nothing to withdraw then warn the user
    require(!nothingToWithdraw, "Nothing to withdraw");
  }

  function _withdraw(uint256 proposalId) private hasProposalById(proposalId) {
    require(block.timestamp > _proposals[proposalId].endsAt, "Proposal still ongoing");
    require(_deposits[proposalId][_msgSender()] > 0, "Nothing to withdraw");
    uint256 quantity = _deposits[proposalId][_msgSender()];
    _deposits[proposalId][_msgSender()] = 0;
    _vyToken.transfer(_msgSender(), quantity);
  }

  function updateAddresses() external override onlyRegistrar {
    _vyToken = VYToken(_registrar.getVYToken());
    _vethYRT = VETHYieldRateTreasury(payable(_registrar.getVETHYieldRateTreasury()));
    _vethRevenueCycleTreasury = VETHRevenueCycleTreasury(_registrar.getVETHRevenueCycleTreasury());
    _vethReverseStakingTreasury = VETHReverseStakingTreasury(payable(_registrar.getVETHReverseStakingTreasury()));
  }
}