// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "./IPRTCLVotes.sol";

/**
 * @dev Modified version of OpenZeppelin's {Votes} to accommodate multiple collections.
 *
 * @author Particle Collection - valdi.eth
 */
abstract contract PRTCLVotes is IPRTCLVotes, Context {
    using Checkpoints for Checkpoints.History;

    mapping(uint256 => mapping(address => address)) private _collectionDelegation;
    mapping(uint256 => mapping(address => Checkpoints.History)) private _collectionDelegateCheckpoints;
    mapping(uint256 => Checkpoints.History) private _collectionTotalCheckpoints;

    /**
     * @dev Returns the current amount of votes that `account` has for a given collection.
     */
    function getVotes(address account, uint256 collectionId) public view virtual override returns (uint256) {
        return _collectionDelegateCheckpoints[collectionId][account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`) for a given collection.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber, uint256 collectionId) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "Votes: block not yet mined");
        return _collectionDelegateCheckpoints[collectionId][account].getAtProbablyRecentBlock(blockNumber);
    }

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`) for a given collection.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber, uint256 collectionId) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "Votes: block not yet mined");
        return _collectionTotalCheckpoints[collectionId].getAtProbablyRecentBlock(blockNumber);
    }

    /**
     * @dev Returns the current total supply of votes for a given collection.
     */
    function getTotalSupply(uint256 collectionId) public view virtual override returns (uint256) {
        return _collectionTotalCheckpoints[collectionId].latest();
    }

    /**
     * @dev Returns the delegate that `account` has chosen for a given collection.
     */
    function delegates(address account, uint256 collectionId) public view virtual override returns (address) {
        return _collectionDelegation[collectionId][account];
    }

    /**
     * @dev Delegates votes from the sender to `delegatee` for a given collection.
     */
    function delegate(address delegatee, uint256 collectionId) public virtual override {
        address account = _msgSender();
        address oldDelegate = delegates(account, collectionId);
        _collectionDelegation[collectionId][account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee, collectionId);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account, collectionId), collectionId);
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint256 amount,
        uint256 collectionId
    ) internal virtual {
        if (from == address(0)) {
            _collectionTotalCheckpoints[collectionId].push(_add, amount);
        }
        if (to == address(0)) {
            _collectionTotalCheckpoints[collectionId].push(_subtract, amount);
        }
        _moveDelegateVotes(delegates(from, collectionId), delegates(to, collectionId), amount, collectionId);
    }

    /**
     * @dev Moves delegated votes from one delegate to another for a given collection.
     */
    function _moveDelegateVotes(
        address from,
        address to,
        uint256 amount,
        uint256 collectionId
    ) private {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                (uint256 oldValue, uint256 newValue) = _collectionDelegateCheckpoints[collectionId][from].push(_subtract, amount);
                emit DelegateVotesChanged(from, oldValue, newValue, collectionId);
            }
            if (to != address(0)) {
                (uint256 oldValue, uint256 newValue) = _collectionDelegateCheckpoints[collectionId][to].push(_add, amount);
                emit DelegateVotesChanged(to, oldValue, newValue, collectionId);
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Must return the voting units held by an account for a given collection.
     */
    function _getVotingUnits(address owner, uint256 collectionId) internal view virtual returns (uint256);
}