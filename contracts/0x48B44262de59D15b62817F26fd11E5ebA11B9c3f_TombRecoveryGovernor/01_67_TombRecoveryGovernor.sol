// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {RecoveryGovernor} from "recovery-protocol/governance/RecoveryGovernor.sol";
import {IndexMarkerV2} from "../IndexMarkerV2.sol";

contract TombRecoveryGovernor is RecoveryGovernor {
    address immutable indexMarkerAddress;

    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public tombVotedOnProposal;

    constructor(address indexMarkerAddress_) {
        indexMarkerAddress = indexMarkerAddress_;
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal override returns (uint256) {
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");
        uint256 weight = _getVotes(account, proposalSnapshot(proposalId), params);
        if (params.length > 0) {
            (address[] memory tombTokenContracts, uint256[] memory tombTokenIds) = abi.decode(
                params,
                (address[], uint256[])
            );
            if (tombTokenContracts.length != tombTokenIds.length) {
                revert("TombRecoveryGovernor: token contract and token id arrays must be the same length");
            }
            for (uint256 i = 0; i < tombTokenIds.length; i++) {
                if (tombTokenContracts[i] == recoveryParentTokenContract && tombTokenIds[i] == recoveryParentTokenId) {
                    continue;
                }
                if (!IndexMarkerV2(indexMarkerAddress).isTomb(tombTokenContracts[i], tombTokenIds[i])) {
                    revert("TombRecoveryGovernor: token provided is not a tomb");
                }
                if (IERC721Upgradeable(tombTokenContracts[i]).ownerOf(tombTokenIds[i]) != account) {
                    revert("TombRecoveryGovernor: token provided is not owned by voter");
                }
                if (tombVotedOnProposal[tombTokenContracts[i]][tombTokenIds[i]][proposalId]) {
                    revert("TombRecoveryGovernor: tomb already voted on proposal");
                }
                tombVotedOnProposal[tombTokenContracts[i]][tombTokenIds[i]][proposalId] = true;
                weight += 1;
            }
        }

        if (account == recoveryParentTokenOwner()) {
            require(
                !recoveryParentTokenOwnerVotedOnProposal[proposalId],
                "Governor: recovery parent token owner already voted on proposal"
            );
            recoveryParentTokenOwnerVotedOnProposal[proposalId] = true;
            weight += recoveryParentTokenOwnerVotingWeight;
        }
        _countVote(proposalId, account, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(account, proposalId, support, weight, reason, params);
        }

        return weight;
    }

    function quorumDenominator() public view override returns (uint256) {
        return 1000;
    }

    // extra storage
    uint256[50] private __gap;
}