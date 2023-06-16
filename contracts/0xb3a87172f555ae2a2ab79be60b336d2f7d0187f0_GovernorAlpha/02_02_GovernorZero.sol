pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../GovernorAlpha.sol";

contract GovernorZero is GovernorAlpha {

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() public pure returns (uint) { return 1e18; } // 1% of Pool

  /// @notice The number of votes required in order for a voter to become a proposer
  function proposalThreshold() public pure returns (uint) { return 1e18; }

  /// @notice The maximum number of actions that can be included in a proposal
  function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

  /// @notice The delay before voting on a proposal may take place, once proposed
  function votingDelay() public pure returns (uint) { return 0; } // 1 block

  /// @notice The duration of voting on a proposal, in blocks
  function votingPeriod() public pure returns (uint) { return 100; } // ~7 days in blocks (assuming 15s blocks)

  constructor(address hermes_, address pool_) public GovernorAlpha(hermes_, pool_) {
  }
}