// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IAgent.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Agent is IAgent, Ownable {
    // Agent related params, should be able to reset this by an owner
    uint256 public initialAgentScore = 100;
    uint256 public criteriaScore = 70;
    uint256 public disputeBonusAmount = 10 * (10**18);
    uint256 public scoreUp = 10;
    uint256 public scoreDown = 10;
    uint256 public disputeReviewGroupCount = 5;//  maximum required agent to resolve a dispute
    uint256 public disputeReviewConsensusCount = 3;
    uint256 public agentPaticipateAmount = 5 * (10**18);
    uint public maxReviewDelay = 20 seconds; // maximum period to resolve a dispute
    // Agent Status
    uint256 constant _INIT = 1;
    uint256 constant _WAITING = 2;
    uint256 constant _REVIEW = 3;
    uint256 constant _APPROVED = 4;
    uint256 constant _DISAPPROVED = 5;
    uint256 constant _EARNED = 6;
    uint256 constant _LOST = 7;
    uint256 constant _BAN = 8;

    mapping(address => Agent) public agents;

    function resetInitialAgentScore(uint256 _newInitialAgentScore)
        external
        onlyOwner
    {
        require(_newInitialAgentScore > 0, "Invalid value");
        initialAgentScore = _newInitialAgentScore;
    }
    function resetMaxReviewDelay(uint256 newMaxReviewDelay) external onlyOwner{
        require(newMaxReviewDelay > 0, "Invalid value");
        maxReviewDelay = newMaxReviewDelay;
    }
    function resetCriteriaScore(uint256 _newCriteriaScore) external onlyOwner {
        require(_newCriteriaScore >= 0, "Invalid value");
        criteriaScore = _newCriteriaScore;
    }

    function resetDisputeBonusAmount(uint256 _newDisputeBonusAmount)
        external
        onlyOwner
    {
        require(_newDisputeBonusAmount >= 0, "Invalid value");
        disputeBonusAmount = _newDisputeBonusAmount * (10**18);
    }

    function resetScoreUp(uint256 _newScoreUp) external onlyOwner {
        require(_newScoreUp >= 0, "Invalid value");
        scoreUp = _newScoreUp;
    }

    function resetScoreDown(uint256 _newScoreDown) external onlyOwner {
        require(_newScoreDown >= 0, "Invalid value");
        scoreDown = _newScoreDown;
    }

    function resetDisputeReviewGroupCount(uint256 _newDisputeReviewGroupCount)
        external
        onlyOwner
    {
        require(_newDisputeReviewGroupCount > 0, "Invalid value");
        require(
            _newDisputeReviewGroupCount >= disputeReviewConsensusCount,
            "Should be larger number than the Consensus count"
        );
        disputeReviewGroupCount = _newDisputeReviewGroupCount;
    }

    function resetDisputeReviewConsensusCount(
        uint256 _newDisputeReviewConsensusCount
    ) external onlyOwner {
        require(_newDisputeReviewConsensusCount > 0, "Invalid value");
        require(
            _newDisputeReviewConsensusCount <= disputeReviewGroupCount,
            "Should be smaller number than the Group count"
        );
        disputeReviewConsensusCount = _newDisputeReviewConsensusCount;
    }

    function resetAgentPaticipateAmount(uint256 _newAgentPaticipateAmount)
        external
        onlyOwner
    {
        require(_newAgentPaticipateAmount > 0, "Invalid value");
        agentPaticipateAmount = _newAgentPaticipateAmount * (10**18);
    }
}