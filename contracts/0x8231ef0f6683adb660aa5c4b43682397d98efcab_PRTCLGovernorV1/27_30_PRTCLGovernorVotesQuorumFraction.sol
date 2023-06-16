// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PRTCLGovernorVotes.sol";
import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev Extension of {PRTCLGovernorVotes} for voting weight extraction from an {PRTCLCoreERC721Votes} token and a quorum expressed as a
 * fraction of the total supply.
 *
 * Modified version of OpenZeppelin's GovernorVotesQuorumFraction.sol:
 * 1. Uses votesToken from PRTCLGovernorVotes
 * 2. Implements `function quorum(uint256 blockNumber, uint256 collectionId)`
 * 3. Removes deprecated `_quorumNumerator` storage
 * 4. Override `updateQuorumNumerator` to be onlyOwner
 * 
 * Known limitation: Only one `quorumNumerator` for all collections.
 *
 * @author Particle Collection - valdi.eth
 */
abstract contract PRTCLGovernorVotesQuorumFraction is PRTCLGovernorVotes {
    using Checkpoints for Checkpoints.History;

    Checkpoints.History private _quorumNumeratorHistory;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    /**
     * @dev Initialize quorum as a fraction of the token's total supply.
     *
     * The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
     * specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
     * customized by overriding {quorumDenominator}.
     */
    constructor(uint256 quorumNumeratorValue) {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumeratorHistory.latest();
    }

    /**
     * @dev Returns the quorum numerator at a specific block number. See {quorumDenominator}.
     */
    function quorumNumerator(uint256 blockNumber) public view virtual returns (uint256) {
        // Optimistic search, check the latest checkpoint
        Checkpoints.Checkpoint memory latest = _quorumNumeratorHistory._checkpoints[_quorumNumeratorHistory._checkpoints.length - 1];
        if (latest._blockNumber <= blockNumber) {
            return latest._value;
        }

        // Otherwise, do the binary search
        return _quorumNumeratorHistory.getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
     */
    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev Returns the quorum for a block number for collection `collectionId`,
     * in terms of number of votes: `supply * numerator / denominator`, rounded up.
     */
    function quorum(uint256 blockNumber, uint256 collectionId) public view virtual override returns (uint256) {
        return _ceilDiv(votesToken.getPastTotalSupply(blockNumber, collectionId) * quorumNumerator(blockNumber), quorumDenominator());
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - Must be called by the owner.
     * - New numerator must be smaller or equal to the denominator.
     */
    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyOwner {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - New numerator must be smaller or equal to the denominator.
     */
    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = quorumNumerator();

        // Set new quorum for future proposals
        _quorumNumeratorHistory.push(newQuorumNumerator);

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     *
     * Implementation from OpenZeppelin's SafeMath.sol
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.2/contracts/utils/math/Math.sol#L45
     */
    function _ceilDiv(uint256 a, uint256 b) private pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }
}