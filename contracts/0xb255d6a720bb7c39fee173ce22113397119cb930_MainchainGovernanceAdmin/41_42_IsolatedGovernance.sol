// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/consumers/VoteStatusConsumer.sol";

library IsolatedGovernance {
  struct Vote {
    VoteStatusConsumer.VoteStatus status;
    bytes32 finalHash;
    /// @dev Mapping from voter => receipt hash
    mapping(address => bytes32) voteHashOf;
    /// @dev The timestamp that voting is expired (no expiration=0)
    uint256 expiredAt;
    /// @dev The timestamp that voting is created
    uint256 createdAt;
    /// @dev The list of voters
    address[] voters;
  }

  /**
   * @dev Casts vote for the receipt with the receipt hash `_hash`.
   *
   * Requirements:
   * - The voter has not voted for the round.
   *
   */
  function castVote(
    Vote storage _v,
    address _voter,
    bytes32 _hash
  ) internal {
    if (_v.expiredAt > 0 && _v.expiredAt <= block.timestamp) {
      _v.status = VoteStatusConsumer.VoteStatus.Expired;
    }

    if (voted(_v, _voter)) {
      revert(
        string(abi.encodePacked("IsolatedGovernance: ", Strings.toHexString(uint160(_voter), 20), " already voted"))
      );
    }

    _v.voteHashOf[_voter] = _hash;
    _v.voters.push(_voter);
  }

  /**
   * @dev Updates vote with the requirement of minimum vote weight.
   */
  function syncVoteStatus(
    Vote storage _v,
    uint256 _minimumVoteWeight,
    uint256 _votedWeightForHash,
    uint256 _minimumTrustedVoteWeight,
    uint256 _trustedVotedWeightForHash,
    bytes32 _hash
  ) internal returns (VoteStatusConsumer.VoteStatus _status) {
    if (
      _votedWeightForHash >= _minimumVoteWeight &&
      _trustedVotedWeightForHash >= _minimumTrustedVoteWeight &&
      _v.status == VoteStatusConsumer.VoteStatus.Pending
    ) {
      _v.status = VoteStatusConsumer.VoteStatus.Approved;
      _v.finalHash = _hash;
    }

    return _v.status;
  }

  /**
   * @dev Returns the list of vote's addresses that voted for the hash `_hash`.
   */
  function filterByHash(Vote storage _v, bytes32 _hash) internal view returns (address[] memory _voters) {
    uint256 _count;
    _voters = new address[](_v.voters.length);

    for (uint _i; _i < _voters.length; _i++) {
      address _voter = _v.voters[_i];
      if (_v.voteHashOf[_voter] == _hash) {
        _voters[_count++] = _voter;
      }
    }

    assembly {
      mstore(_voters, _count)
    }
  }

  /**
   * @dev Returns whether the voter casted for the proposal.
   */
  function voted(Vote storage _v, address _voter) internal view returns (bool) {
    return _v.voteHashOf[_voter] != bytes32(0);
  }
}