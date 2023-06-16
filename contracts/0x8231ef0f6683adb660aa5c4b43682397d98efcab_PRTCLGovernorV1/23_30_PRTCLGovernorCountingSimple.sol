// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PRTCLBaseGovernor.sol";

 /**
 * @dev Extension of {PRTCLBaseGovernor} for simple, 3 options, vote counting.
 *
 * Modified version of OpenZeppelin's {GovernorCountingSimple}.
 * 
 * @author Particle Collection - valdi.eth
 */
abstract contract PRTCLGovernorCountingSimple is PRTCLBaseGovernor {
    /**
     * @dev Supported vote types.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IPRTCLBaseGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "quorum=against,for,abstain";
    }

    /**
     * @dev See {IPRTCLBaseGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    /**
     * @dev See {PRTCLBaseGovernor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        // Quorum can be 0 in the case of a proposal with one possible vote to be cast.
        // In that case, the quorum is reached even if no votes have been cast.
        // As that is a very unlikely scenario, we can safely disregard it.
        return quorum(proposalSnapshot(proposalId), proposalCollection(proposalId)) <= proposalVote.forVotes + proposalVote.abstainVotes + proposalVote.againstVotes;
    }

    /**
     * @dev See {PRTCLBaseGovernor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }

    /**
     * @dev See {PRTCLBaseGovernor-_countVote}. In this module, the support follows the `VoteType` enum.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight
    ) internal virtual override {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        require(!proposalVote.hasVoted[account], "PRTCLGovernorCountingSimple: vote already cast");
        proposalVote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += weight;
        } else {
            revert("PRTCLGovernorCountingSimple: invalid value for enum VoteType");
        }
    }
}