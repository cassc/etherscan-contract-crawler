// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * An Azorius extension contract that enables percent based voting basis calculations.
 *
 * Intended to be implemented by BaseStrategy implementations, this allows for voting strategies
 * to dictate any basis strategy for passing a Proposal between >50% (simple majority) to 100%.
 *
 * See https://en.wikipedia.org/wiki/Voting#Voting_basis.
 * See https://en.wikipedia.org/wiki/Supermajority.
 */
abstract contract BaseVotingBasisPercent is OwnableUpgradeable {
    
    /** The numerator to use when calculating basis (adjustable). */
    uint256 public basisNumerator;

    /** The denominator to use when calculating basis (1,000,000). */
    uint256 public constant BASIS_DENOMINATOR = 1_000_000;

    error InvalidBasisNumerator();

    event BasisNumeratorUpdated(uint256 basisNumerator);

    /**
     * Updates the `basisNumerator` for future Proposals.
     *
     * @param _basisNumerator numerator to use
     */
    function updateBasisNumerator(uint256 _basisNumerator) public virtual onlyOwner {
        _updateBasisNumerator(_basisNumerator);
    }

    /** Internal implementation of `updateBasisNumerator`. */
    function _updateBasisNumerator(uint256 _basisNumerator) internal virtual {
        if (_basisNumerator > BASIS_DENOMINATOR || _basisNumerator < BASIS_DENOMINATOR / 2)
            revert InvalidBasisNumerator();

        basisNumerator = _basisNumerator;

        emit BasisNumeratorUpdated(_basisNumerator);
    }

    /**
     * Calculates whether a vote meets its basis.
     *
     * @param _yesVotes number of votes in favor
     * @param _noVotes number of votes against
     * @return bool whether the yes votes meets the set basis
     */
    function meetsBasis(uint256 _yesVotes, uint256 _noVotes) public view returns (bool) {
        return _yesVotes > (_yesVotes + _noVotes) * basisNumerator / BASIS_DENOMINATOR;
    }
}