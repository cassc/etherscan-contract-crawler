// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "./TSVesting.sol";

contract TSGovernor is
    Governor,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction
{
    address private owner;
    uint private constant PERCENT_VOTE_DISBURMENT_SUCCESS = 51;
    uint private constant PERCENT_VOTE_REFUND_SUCCESS = 67;

    uint256 private voteDelayArg;
    uint256 private votePeriodArg;
    bool private enableDynamicTime;
    address private tokenVesting;
    uint256 public totalDisburment;
    uint256 private percentRemaining;
    uint256 private amountRemaining;
    mapping(uint256 => VoteHistory) private history;

    struct VoteHistory {
        bool voteRefund;
        uint256 amount;
        uint256 fee;
        uint256 percent;
        bool callVt;
        uint256 numberVote;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "TSGovernor: only owner call");
        _;
    }

    constructor(IVotes _token)
        Governor("TSGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(PERCENT_VOTE_DISBURMENT_SUCCESS)
    {
        tokenVesting = address(_token);
        owner = msg.sender;
    }

    function votingDelay() public view override returns (uint256) {
        return !enableDynamicTime ? 1 : voteDelayArg; // 1 block
    }

    function votingPeriod() public view override returns (uint256) {
        return !enableDynamicTime ? 45818 : votePeriodArg;
    }

    // The following functions are overrides required by Solidity.
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        uint256 delayVote,
        uint256 periodVote,
        bool voteRefund,
        uint256 percent,
        uint256 amount,
        uint256 fee
    ) public onlyOwner returns (uint256 proposalId) {
        _beforeCreatePropose(delayVote, periodVote);
        proposalId = propose(targets, values, calldatas, description);
        history[proposalId] = VoteHistory(voteRefund, amount, fee, percent, false, 0);
        if(!voteRefund) {
            percentRemaining = percent;
            amountRemaining = amount+fee;
        }
        _afterCreatePropose();
    }

    function checkVote(uint256 proposalId) public onlyOwner {
        if(state(proposalId)==ProposalState.Succeeded || state(proposalId)==ProposalState.Executed) {
            TSVesting tsVesting = TSVesting(tokenVesting);
            if(history[proposalId].voteRefund) {
                tsVesting.setRefundInfo(history[proposalId].amount,history[proposalId].fee);
            }else if(!history[proposalId].callVt){
                history[proposalId].callVt = true;
                tsVesting.addRate(history[proposalId].percent);
                totalDisburment += amountRemaining;
            }
            percentRemaining = 0;
            amountRemaining = 0;
        }
    }

    function getRemainingInfo() public view returns(uint256, uint256){
        return (percentRemaining, amountRemaining);
    }

    function getAmountTokenClaim(uint256 proposalId) public view returns(uint256 amountClaim,uint256 amountClaimed,uint256 fee) {
        amountClaim = state(proposalId)==ProposalState.Executed ? 0 : history[proposalId].amount;
        amountClaimed = history[proposalId].amount - amountClaim;
        fee = history[proposalId].fee;
    }

    function _beforeCreatePropose(uint256 delayVote, uint256 periodVote)
        private
    {
        enableDynamicTime = true;
        voteDelayArg = delayVote;
        votePeriodArg = periodVote;
    }

    function _afterCreatePropose()
        private
    {
        enableDynamicTime = false;
        voteDelayArg = 0;
        votePeriodArg = 0;
    }
    /**
     * Customize vote
     */

    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        history[proposalId].numberVote += 1;
        return _castVote(proposalId, voter, support, "");
    }

    function _quorumReached(uint256 proposalId) internal view virtual override(Governor, GovernorCountingSimple) returns (bool) {
        TSVesting tsVesting = TSVesting(tokenVesting);
        return history[proposalId].numberVote*100 >= PERCENT_VOTE_DISBURMENT_SUCCESS * tsVesting.totalUserInvest();
    }

    function _voteSucceeded(uint256 proposalId) internal view virtual override(Governor, GovernorCountingSimple) returns (bool) {
        (, uint256 forVotes, ) = proposalVotes(proposalId);
        TSVesting tsVesting = TSVesting(tokenVesting);
        uint256 pencent = history[proposalId].voteRefund ? PERCENT_VOTE_REFUND_SUCCESS : PERCENT_VOTE_DISBURMENT_SUCCESS;
        return forVotes * 100 >= pencent * tsVesting.total();
    }

}