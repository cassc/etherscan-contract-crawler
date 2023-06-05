// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { LinearERC20Voting } from "./LinearERC20Voting.sol";
import { VotesERC20Wrapper } from "../VotesERC20Wrapper.sol";

 /**
  * An extension of [LinearERC20Voting](./azorius/LinearERC20Voting.md) that properly supports
  * [VotesERC20Wrapper](./VotesERC20Wrapper.md) token governance.
  *
  * This snapshots and uses the total supply of the underlying token for calculating quorum,
  * rather than the total supply of *wrapped* tokens, as would be the case without it.
  */
contract LinearERC20WrappedVoting is LinearERC20Voting {

    /** `proposalId` to "past total supply" of tokens. */
    mapping(uint256 => uint256) internal votingSupply;

    /** @inheritdoc LinearERC20Voting*/
    function initializeProposal(bytes memory _data) public virtual override onlyAzorius {
        uint32 proposalId = abi.decode(_data, (uint32));
        uint32 _votingEndBlock = uint32(block.number) + votingPeriod;

        proposalVotes[proposalId].votingEndBlock = _votingEndBlock;
        proposalVotes[proposalId].votingStartBlock = uint32(block.number);
        votingSupply[proposalId] = VotesERC20Wrapper(address(governanceToken)).underlying().totalSupply();

        emit ProposalInitialized(proposalId, _votingEndBlock);
    }

    /** @inheritdoc LinearERC20Voting*/
    function getProposalVotingSupply(uint32 _proposalId) public view override returns (uint256) {
        return votingSupply[_proposalId];
    }
}