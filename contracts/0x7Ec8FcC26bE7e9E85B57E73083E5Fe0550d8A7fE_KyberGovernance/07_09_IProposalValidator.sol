// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IKyberGovernance} from './IKyberGovernance.sol';
import {IVotingPowerStrategy} from './IVotingPowerStrategy.sol';

interface IProposalValidator {
  /**
   * @dev Called to validate a binary proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param creator address of the creator
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param daoOperator address of daoOperator
   * @return boolean, true if can be created
   **/
  function validateBinaryProposalCreation(
    IVotingPowerStrategy strategy,
    address creator,
    uint256 startTime,
    uint256 endTime,
    address daoOperator
  ) external view returns (bool);

  /**
   * @dev Called to validate a generic proposal
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param creator address of the creator
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param options list of proposal vote options
   * @param daoOperator address of daoOperator
   * @return boolean, true if can be created
   **/
  function validateGenericProposalCreation(
    IVotingPowerStrategy strategy,
    address creator,
    uint256 startTime,
    uint256 endTime,
    string[] calldata options,
    address daoOperator
  ) external view returns (bool);

  /**
   * @dev Called to validate the cancellation of a proposal
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the generic proposal
   * @param user entity initiating the cancellation
   * @return boolean, true if can be cancelled
   **/
  function validateProposalCancellation(
    IKyberGovernance governance,
    uint256 proposalId,
    address user
  ) external view returns (bool);

  /**
   * @dev Returns whether a binary proposal passed or not
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to set
   * @return true if proposal passed
   **/
  function isBinaryProposalPassed(IKyberGovernance governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has reached quorum
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to verify
   * @return voting power needed for a proposal to pass
   **/
  function isQuorumValid(IKyberGovernance governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to verify
   * @return true if enough For-Votes
   **/
  function isVoteDifferentialValid(IKyberGovernance governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Get maximum vote options for a generic proposal
   * @return the maximum no. of vote options possible for a generic proposal
   **/
  function MAX_VOTING_OPTIONS() external view returns (uint256);

  /**
   * @dev Get minimum voting duration constant value
   * @return the minimum voting duration value in seconds
   **/
  function MIN_VOTING_DURATION() external view returns (uint256);

  /**
   * @dev Get the vote differential threshold constant value
   * to compare with % of for votes/total supply - % of against votes/total supply
   * @return the vote differential threshold value (100 <=> 1%)
   **/
  function VOTE_DIFFERENTIAL() external view returns (uint256);

  /**
   * @dev Get quorum threshold constant value
   * to compare with % of for votes/total supply
   * @return the quorum threshold value (100 <=> 1%)
   **/
  function MINIMUM_QUORUM() external view returns (uint256);
}