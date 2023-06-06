//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * A specification for a contract which manages the ability to call for and cast a vote
 * to freeze a subDAO.
 *
 * The participants of this vote are parent token holders or signers. The DAO should be
 * able to operate as normal throughout the freeze voting process, however if the vote
 * passes, further transaction executions on the subDAO should be blocked via a Safe guard
 * module (see [MultisigFreezeGuard](../MultisigFreezeGuard.md) / [AzoriusFreezeGuard](../AzoriusFreezeGuard.md)).
 */
interface IBaseFreezeVoting {

    /**
     * Allows an address to cast a "freeze vote", which is a vote to freeze the DAO
     * from executing transactions, even if they've already passed via a Proposal.
     *
     * If a vote to freeze has not already been initiated, a call to this function will do
     * so.
     *
     * This function should be publicly callable by any DAO token holder or signer.
     */
    function castFreezeVote() external;

    /**
     * Unfreezes the DAO.
     */
    function unfreeze() external;

    /**
     * Updates the freeze votes threshold for future freeze votes. This is the number of token
     * votes necessary to begin a freeze on the subDAO.
     *
     * @param _freezeVotesThreshold number of freeze votes required to activate a freeze
     */
    function updateFreezeVotesThreshold(uint256 _freezeVotesThreshold) external;

    /**
     * Updates the freeze proposal period for future freeze votes. This is the length of time
     * (in blocks) that a freeze vote is conducted for.
     *
     * @param _freezeProposalPeriod number of blocks a freeze proposal has to succeed
     */
    function updateFreezeProposalPeriod(uint32 _freezeProposalPeriod) external;

    /**
     * Updates the freeze period. This is the length of time (in blocks) the subDAO is actually
     * frozen for if a freeze vote passes.
     *
     * This period can be overridden by a call to `unfreeze()`, which would require a passed Proposal
     * from the parentDAO.
     *
     * @param _freezePeriod number of blocks a freeze lasts, from time of freeze proposal creation
     */
    function updateFreezePeriod(uint32 _freezePeriod) external;

    /**
     * Returns true if the DAO is currently frozen, false otherwise.
     *
     * @return bool whether the DAO is currently frozen
     */
    function isFrozen() external view returns (bool);
}