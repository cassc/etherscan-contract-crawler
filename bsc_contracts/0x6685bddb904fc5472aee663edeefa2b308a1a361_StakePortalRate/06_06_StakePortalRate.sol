pragma solidity 0.7.6;
// SPDX-License-Identifier: GPL-3.0-only

import "../balancer-metastable-rate-providers/interfaces/IRateProvider.sol";
import "./Multisig.sol";

contract StakePortalRate is Multisig, IRateProvider {
    using SafeCast for *;
    using SafeMath for uint256;

    // ---- storage

    uint256 private rate; // decimals 18
    uint256 public rateChangeLimit; // decimals 18

    // events
    event SetRate(uint256 rate);

    constructor(
        address[] memory _initialSubAccounts,
        uint256 _initialThreshold,
        uint256 _rate
    ) Multisig(_initialSubAccounts, _initialThreshold) {
        require(_rate > 0, "rate zero");

        rate = _rate;
        rateChangeLimit = 1e15; // 0.1%
    }

    // ------ settings

    function setRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "rate zero");
        rate = _rate;
    }

    function setRateChangeLimit(uint256 _rateChangeLimit) external onlyOwner {
        rateChangeLimit = _rateChangeLimit;
    }

    // ----- getters

    function getRate() external view override returns (uint256) {
        return rate;
    }

    // ----- vote

    function voteRate(bytes32 _proposalId, uint256 _rate) public onlySubAccount {
        uint256 rateChange = _rate > rate ? _rate.sub(rate) : rate.sub(_rate);
        require(rateChange.mul(1e18).div(rate) < rateChangeLimit, "rate change over limit");

        Proposal memory proposal = proposals[_proposalId];

        require(uint256(proposal._status) <= 1, "proposal already executed");
        require(!_hasVoted(proposal, msg.sender), "already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({_status: ProposalStatus.Active, _yesVotes: 0, _yesVotesTotal: 0});
        }
        proposal._yesVotes = (proposal._yesVotes | subAccountBit(msg.sender)).toUint16();
        proposal._yesVotesTotal++;

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            rate = _rate;

            emit SetRate(_rate);

            proposal._status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        }
        proposals[_proposalId] = proposal;
    }
}