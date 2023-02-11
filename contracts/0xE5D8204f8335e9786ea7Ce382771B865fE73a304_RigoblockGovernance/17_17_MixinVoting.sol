// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2023 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "./MixinAbstract.sol";
import "./MixinStorage.sol";
import "../interfaces/IGovernanceStrategy.sol";

abstract contract MixinVoting is MixinStorage, MixinAbstract {
    /// @inheritdoc IGovernanceVoting
    function propose(ProposedAction[] memory actions, string memory description)
        external
        override
        returns (uint256 proposalId)
    {
        uint256 length = actions.length;
        require(_getVotingPower(msg.sender) >= _governanceParameters().proposalThreshold, "GOV_LOW_VOTING_POWER");
        require(length > 0, "GOV_NO_ACTIONS_ERROR");
        require(length <= PROPOSAL_MAX_OPERATIONS, "GOV_TOO_MANY_ACTIONS_ERROR");
        (uint256 startBlockOrTime, uint256 endBlockOrTime) = IGovernanceStrategy(_governanceParameters().strategy)
            .votingTimestamps();

        // proposals start from id = 1
        _proposalCount().value++;
        proposalId = _getProposalCount();
        Proposal memory newProposal = Proposal({
            actionsLength: length,
            startBlockOrTime: startBlockOrTime,
            endBlockOrTime: endBlockOrTime,
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            executed: false
        });

        for (uint256 i = 0; i < length; i++) {
            _proposedAction().proposedActionbyIndex[proposalId][i] = actions[i];
        }

        _proposal().proposalById[proposalId] = newProposal;

        emit ProposalCreated(msg.sender, proposalId, actions, startBlockOrTime, endBlockOrTime, description);
    }

    /// @inheritdoc IGovernanceVoting
    function castVote(uint256 proposalId, VoteType voteType) external override {
        _castVote(msg.sender, proposalId, voteType);
    }

    /// @inheritdoc IGovernanceVoting
    function castVoteBySignature(
        uint256 proposalId,
        VoteType voteType,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(_name().value)),
                keccak256(bytes(VERSION)),
                block.chainid,
                address(this)
            )
        );
        bytes32 structHash = keccak256(abi.encode(VOTE_TYPEHASH, proposalId, voteType));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        // following assertion is always bypassed by producing a valid EIP712 signature on diff. domain, therefore we do not return an error
        assert(
            signatory != address(0) && uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        );
        _castVote(signatory, proposalId, voteType);
    }

    /// @inheritdoc IGovernanceVoting
    function execute(uint256 proposalId) external payable override {
        require(_getProposalState(proposalId) == ProposalState.Succeeded, "VOTING_EXECUTION_STATE_ERROR");
        Proposal storage proposal = _proposal().proposalById[proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.actionsLength; i++) {
            ProposedAction memory action = _proposedAction().proposedActionbyIndex[proposalId][i];
            address target = action.target;
            uint256 value = action.value;
            bytes memory data = action.data;

            // we revert with error returned from the target
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let didSucceed := call(gas(), target, value, add(data, 0x20), mload(data), 0, 0)
                returndatacopy(0, 0, returndatasize())
                if eq(didSucceed, 0) {
                    revert(0, returndatasize())
                }
            }
        }

        emit ProposalExecuted(proposalId);
    }

    /// @notice Casts a vote for the given proposal.
    /// @dev Only callable during the voting period for that proposal.
    function _castVote(
        address voter,
        uint256 proposalId,
        VoteType voteType
    ) private {
        require(_getProposalState(proposalId) == ProposalState.Active, "VOTING_CLOSED_ERROR");
        Receipt memory receipt = _receipt().userReceiptByProposal[proposalId][voter];
        require(!receipt.hasVoted, "VOTING_ALREADY_VOTED_ERROR");
        uint256 votingPower = _getVotingPower(voter);
        require(votingPower != 0, "VOTING_NO_VOTES_ERROR");
        Proposal storage proposal = _proposal().proposalById[proposalId];

        if (voteType == VoteType.For) {
            proposal.votesFor += votingPower;
        } else if (voteType == VoteType.Against) {
            proposal.votesAgainst += votingPower;
        } else {
            proposal.votesAbstain += votingPower;
        }

        _receipt().userReceiptByProposal[proposalId][voter] = Receipt({
            hasVoted: true,
            votes: uint96(votingPower),
            voteType: voteType
        });

        // if vote reaches qualified majority we prepare execution at next block
        if (_getProposalState(proposalId) == ProposalState.Qualified) {
            proposal.endBlockOrTime = _paramsWrapper().governanceParameters.timeType == TimeType.Timestamp
                ? block.timestamp
                : block.number;
        }

        emit VoteCast(voter, proposalId, voteType, votingPower);
    }
}