//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { BaseFreezeVoting, IBaseFreezeVoting } from "./BaseFreezeVoting.sol";
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";

/**
 * A [BaseFreezeVoting](./BaseFreezeVoting.md) implementation which handles 
 * freezes on ERC20 based token voting DAOs.
 */
contract ERC20FreezeVoting is BaseFreezeVoting {

    /** A reference to the ERC20 voting token of the subDAO. */
    IVotes public votesERC20;

    event ERC20FreezeVotingSetUp(
        address indexed owner,
        address indexed votesERC20
    );

    error NoVotes();
    error AlreadyVoted();

    /**
     * Initialize function, will be triggered when a new instance is deployed.
     *
     * @param initializeParams encoded initialization parameters: `address _owner`,
     * `uint256 _freezeVotesThreshold`, `uint256 _freezeProposalPeriod`, `uint256 _freezePeriod`,
     * `address _votesERC20`
     */
    function setUp(bytes memory initializeParams) public override initializer {
        (
            address _owner,
            uint256 _freezeVotesThreshold,
            uint32 _freezeProposalPeriod,
            uint32 _freezePeriod,
            address _votesERC20
        ) = abi.decode(
                initializeParams,
                (address, uint256, uint32, uint32, address)
            );

        __Ownable_init();
        _transferOwnership(_owner);
        _updateFreezeVotesThreshold(_freezeVotesThreshold);
        _updateFreezeProposalPeriod(_freezeProposalPeriod);
        _updateFreezePeriod(_freezePeriod);
        freezePeriod = _freezePeriod;
        votesERC20 = IVotes(_votesERC20);

        emit ERC20FreezeVotingSetUp(_owner, _votesERC20);
    }

    /** @inheritdoc BaseFreezeVoting*/
    function castFreezeVote() external override {
        uint256 userVotes;

        if (block.number > freezeProposalCreatedBlock + freezeProposalPeriod) {
            // create a new freeze proposal and set total votes to msg.sender's vote count

            freezeProposalCreatedBlock = uint32(block.number);

            userVotes = votesERC20.getPastVotes(
                msg.sender,
                freezeProposalCreatedBlock - 1
            );

            if (userVotes == 0) revert NoVotes();

            freezeProposalVoteCount = userVotes;

            emit FreezeProposalCreated(msg.sender);
        } else {
            // there is an existing freeze proposal, count user's votes toward it

            if (userHasFreezeVoted[msg.sender][freezeProposalCreatedBlock])
                revert AlreadyVoted();

            userVotes = votesERC20.getPastVotes(
                msg.sender,
                freezeProposalCreatedBlock - 1
            );

            if (userVotes == 0) revert NoVotes();

            freezeProposalVoteCount += userVotes;
        }        

        userHasFreezeVoted[msg.sender][freezeProposalCreatedBlock] = true;

        emit FreezeVoteCast(msg.sender, userVotes);
    }
}