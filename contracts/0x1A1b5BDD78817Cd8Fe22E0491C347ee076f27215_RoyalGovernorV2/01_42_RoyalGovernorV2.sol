// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IQueenPalace} from "../../interfaces/IQueenPalace.sol";

/// @custom:security-contact [email protected]
contract RoyalGovernorV2 is
  Governor,
  GovernorSettings,
  GovernorCompatibilityBravo,
  GovernorVotes,
  GovernorVotesQuorumFraction,
  GovernorTimelockControl,
  Ownable,
  ReentrancyGuard
{
  event ProposalVetoed(uint256 id);

  IQueenPalace internal queenPalace;
  address public vetoer;
  uint256 public vetoPowerUntil;

  modifier onlyOwnerOrDAO() {
    isOwnerOrDAO();
    _;
  }

  modifier onlyOnImplementationOrDAO() {
    isOnImplementationOrDAO();
    _;
  }

  function isOwnerOrDAO() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.daoExecutor(),
      "Not Owner, DAO"
    );
  }

  function isOnImplementationOrDAO() internal view {
    require(
      queenPalace.isOnImplementation() ||
        msg.sender == queenPalace.daoExecutor(),
      "Not On Implementation sender not DAO"
    );
  }

  constructor(
    IVotes _token,
    TimelockController _timelock,
    IQueenPalace _queenPalace,
    address _vetoer,
    uint256 _vetoPowerUntil,
    uint256 _quorumPercentage,
    uint256 _votingPeriod,
    uint256 _votingDelay
  )
    Governor("RoyalGovernor")
    GovernorSettings(_votingDelay, _votingPeriod, 1)
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(_quorumPercentage)
    GovernorTimelockControl(_timelock)
  {
    queenPalace = _queenPalace;
    vetoer = _vetoer;
    vetoPowerUntil = _vetoPowerUntil;
  }

  /**
   *IN
   *_queenPalace: address of queen palace contract
   *OUT
   */
  function setQueenPalace(IQueenPalace _queenPalace)
    external
    nonReentrant
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    _setQueenPalace(_queenPalace);
  }

  /**
   *IN
   *_queenPalace: address of queen palace contract
   *OUT
   */
  function _setQueenPalace(IQueenPalace _queenPalace) internal {
    queenPalace = _queenPalace;
  }

  // The following functions are overrides required by Solidity.

  function votingDelay()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingDelay();
  }

  function votingPeriod()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingPeriod();
  }

  function quorum(uint256 blockNumber)
    public
    view
    override(IGovernor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  function getVotes(address account, uint256 blockNumber)
    public
    view
    override(IGovernor, Governor)
    returns (uint256)
  {
    return super.getVotes(account, blockNumber);
  }

  /**
   * @dev See {IGovernor-castVote}.
   */
  function castVote(uint256 proposalId, uint8 support)
    public
    override(Governor, IGovernor)
    returns (uint256)
  {
    require(
      getVotes(msg.sender, proposalSnapshot(proposalId)) > 0,
      "UnWealthyDAO::vote: Zero Voting Power"
    );

    return super.castVote(proposalId, support);
  }

  /**
   * @dev See {IGovernor-castVoteWithReason}.
   */
  function castVoteWithReason(
    uint256 proposalId,
    uint8 support,
    string calldata reason
  ) public override(Governor, IGovernor) returns (uint256) {
    require(
      getVotes(msg.sender, proposalSnapshot(proposalId)) > 0,
      "UnWealthyDAO::vote: Zero Voting Power"
    );

    return super.castVoteWithReason(proposalId, support, reason);
  }

  function state(uint256 proposalId)
    public
    view
    override(Governor, IGovernor, GovernorTimelockControl)
    returns (ProposalState)
  {
    return super.state(proposalId);
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description
  )
    public
    override(Governor, GovernorCompatibilityBravo, IGovernor)
    returns (uint256)
  {
    require(
      queenPalace.QueenE().isHouseOfLordsFull() ||
        queenPalace.QueenE()._currentAuctionQueenE() > 60,
      "UnWealthyDAO::propose: Parliament not open for proposals"
    );
    require(queenPalace.QueenE().getHouseSeat(msg.sender) != 3, "BANNED");
    return super.propose(targets, values, calldatas, description);
  }

  function proposalThreshold()
    public
    view
    override(Governor, GovernorSettings)
    returns (uint256)
  {
    return super.proposalThreshold();
  }

  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) {
    super._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  /**
   * @notice Vetoes a proposal only if sender is the vetoer and the proposal has not been executed.
   * @param proposalId The id of the proposal to veto
   */
  function veto(uint256 proposalId, bytes32 descriptionHash) external {
    require(vetoer != address(0), "UnWealthyDAO::veto: veto power burned");
    require(msg.sender == vetoer, "UnWealthyDAO::veto: only vetoer");
    require(
      state(proposalId) != ProposalState.Executed,
      "UnWealthyDAO::veto: cannot veto executed proposal"
    );
    require(
      queenPalace.QueenE()._currentAuctionQueenE() <= vetoPowerUntil,
      "UnWealthyDAO::veto: Veto power obsolete"
    );

    (
      address[] memory targets,
      uint256[] memory values, //string[] memory signatures,
      ,
      bytes[] memory calldatas
    ) = getActions(proposalId);

    _cancel(targets, values, calldatas, descriptionHash);

    emit ProposalVetoed(proposalId);
  }

  function _executor()
    internal
    view
    override(Governor, GovernorTimelockControl)
    returns (address)
  {
    return super._executor();
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(Governor, IERC165, GovernorTimelockControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}