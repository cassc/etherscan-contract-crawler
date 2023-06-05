//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { FactoryFriendly } from "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";
import { IBaseFreezeVoting } from "./interfaces/IBaseFreezeVoting.sol";

/**
 * The base abstract contract which holds the state of a vote to freeze a childDAO.
 *
 * The freeze feature gives a way for parentDAOs to have a limited measure of control
 * over their created subDAOs.
 *
 * Normally a subDAO operates independently, and can vote on or sign transactions, 
 * however should the parent disagree with a decision made by the subDAO, any parent
 * token holder can initiate a vote to "freeze" it, making executing transactions impossible
 * for the time denoted by `freezePeriod`.
 *
 * This requires a number of votes equal to `freezeVotesThreshold`, within the `freezeProposalPeriod`
 * to be successful.
 *
 * Following a successful freeze vote, the childDAO will be unable to execute transactions, due to
 * a Safe Transaction Guard, until the `freezePeriod` has elapsed.
 */
abstract contract BaseFreezeVoting is FactoryFriendly, IBaseFreezeVoting {

    /** Block number the freeze proposal was created at. */
    uint32 public freezeProposalCreatedBlock;

    /** Number of blocks a freeze proposal has to succeed. */
    uint32 public freezeProposalPeriod;

    /** Number of blocks a freeze lasts, from time of freeze proposal creation. */
    uint32 public freezePeriod;

    /** Number of freeze votes required to activate a freeze. */
    uint256 public freezeVotesThreshold;

    /** Number of accrued freeze votes. */
    uint256 public freezeProposalVoteCount;

    /**
    * Mapping of address to the block the freeze vote was started to 
    * whether the address has voted yet on the freeze proposal.
    */
    mapping(address => mapping(uint256 => bool)) public userHasFreezeVoted;

    event FreezeVoteCast(address indexed voter, uint256 votesCast);
    event FreezeProposalCreated(address indexed creator);
    event FreezeVotesThresholdUpdated(uint256 freezeVotesThreshold);
    event FreezePeriodUpdated(uint32 freezePeriod);
    event FreezeProposalPeriodUpdated(uint32 freezeProposalPeriod);

    constructor() {
      _disableInitializers();
    }

    /**
     * Casts a positive vote to freeze the subDAO. This function is intended to be called
     * by the individual token holders themselves directly, and will allot their token
     * holdings a "yes" votes towards freezing.
     *
     * Additionally, if a vote to freeze is not already running, calling this will initiate
     * a new vote to freeze it.
     */
    function castFreezeVote() external virtual;

    /**
     * Returns true if the DAO is currently frozen, false otherwise.
     * 
     * @return bool whether the DAO is currently frozen
     */
    function isFrozen() external view returns (bool) {
        return freezeProposalVoteCount >= freezeVotesThreshold 
            && block.number < freezeProposalCreatedBlock + freezePeriod;
    }

    /**
     * Unfreezes the DAO, only callable by the owner (parentDAO).
     */
    function unfreeze() external onlyOwner {
        freezeProposalCreatedBlock = 0;
        freezeProposalVoteCount = 0;
    }

    /**
     * Updates the freeze votes threshold, the number of votes required to enact a freeze.
     *
     * @param _freezeVotesThreshold number of freeze votes required to activate a freeze
     */
    function updateFreezeVotesThreshold(uint256 _freezeVotesThreshold) external onlyOwner {
        _updateFreezeVotesThreshold(_freezeVotesThreshold);
    }

    /**
     * Updates the freeze proposal period, the time that parent token holders have to cast votes
     * after a freeze vote has been initiated.
     *
     * @param _freezeProposalPeriod number of blocks a freeze vote has to succeed to enact a freeze
     */
    function updateFreezeProposalPeriod(uint32 _freezeProposalPeriod) external onlyOwner {
        _updateFreezeProposalPeriod(_freezeProposalPeriod);
    }

    /**
     * Updates the freeze period, the time the DAO will be unable to execute transactions for,
     * should a freeze vote pass.
     *
     * @param _freezePeriod number of blocks a freeze lasts, from time of freeze proposal creation
     */
    function updateFreezePeriod(uint32 _freezePeriod) external onlyOwner {
        _updateFreezePeriod(_freezePeriod);
    }

    /** Internal implementation of `updateFreezeVotesThreshold`. */
    function _updateFreezeVotesThreshold(uint256 _freezeVotesThreshold) internal {
        freezeVotesThreshold = _freezeVotesThreshold;
        emit FreezeVotesThresholdUpdated(_freezeVotesThreshold);
    }

    /** Internal implementation of `updateFreezeProposalPeriod`. */
    function _updateFreezeProposalPeriod(uint32 _freezeProposalPeriod) internal {
        freezeProposalPeriod = _freezeProposalPeriod;
        emit FreezeProposalPeriodUpdated(_freezeProposalPeriod);
    }

    /** Internal implementation of `updateFreezePeriod`. */
    function _updateFreezePeriod(uint32 _freezePeriod) internal {
        freezePeriod = _freezePeriod;
        emit FreezePeriodUpdated(_freezePeriod);
    }
}