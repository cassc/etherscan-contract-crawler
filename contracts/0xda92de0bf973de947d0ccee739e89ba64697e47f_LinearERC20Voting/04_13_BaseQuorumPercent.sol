// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * An Azorius extension contract that enables percent based quorums.
 * Intended to be implemented by [BaseStrategy](./BaseStrategy.md) implementations.
 */
abstract contract BaseQuorumPercent is OwnableUpgradeable {
    
    /** The numerator to use when calculating quorum (adjustable). */
    uint256 public quorumNumerator;

    /** The denominator to use when calculating quorum (1,000,000). */
    uint256 public constant QUORUM_DENOMINATOR = 1_000_000;

    /** Ensures the numerator cannot be larger than the denominator. */
    error InvalidQuorumNumerator();

    event QuorumNumeratorUpdated(uint256 quorumNumerator);

    /** 
     * Updates the quorum required for future Proposals.
     *
     * @param _quorumNumerator numerator to use when calculating quorum (over 1,000,000)
     */
    function updateQuorumNumerator(uint256 _quorumNumerator) public virtual onlyOwner {
        _updateQuorumNumerator(_quorumNumerator);
    }

    /** Internal implementation of `updateQuorumNumerator`. */
    function _updateQuorumNumerator(uint256 _quorumNumerator) internal virtual {
        if (_quorumNumerator > QUORUM_DENOMINATOR)
            revert InvalidQuorumNumerator();

        quorumNumerator = _quorumNumerator;

        emit QuorumNumeratorUpdated(_quorumNumerator);
    }

    /**
     * Calculates whether a vote meets quorum. This is calculated based on yes votes + abstain
     * votes.
     *
     * @param _totalSupply the total supply of tokens
     * @param _yesVotes number of votes in favor
     * @param _abstainVotes number of votes abstaining
     * @return bool whether the total number of yes votes + abstain meets the quorum
     */
    function meetsQuorum(uint256 _totalSupply, uint256 _yesVotes, uint256 _abstainVotes) public view returns (bool) {
        return _yesVotes + _abstainVotes >= (_totalSupply * quorumNumerator) / QUORUM_DENOMINATOR;
    }

    /**
     * Calculates the total number of votes required for a proposal to meet quorum.
     * 
     * @param _proposalId The ID of the proposal to get quorum votes for
     * @return uint256 The quantity of votes required to meet quorum
     */
    function quorumVotes(uint32 _proposalId) public view virtual returns (uint256);
}