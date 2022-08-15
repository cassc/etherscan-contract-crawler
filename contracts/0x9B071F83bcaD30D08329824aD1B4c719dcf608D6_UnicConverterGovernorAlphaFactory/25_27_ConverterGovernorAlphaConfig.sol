pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ConverterGovernorAlphaConfig is Ownable {
    uint public constant MINIMUM_DELAY = 1 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    // 1000 / quorumVotesDivider = percentage needed
    uint public quorumVotesDivider;
    // 1000 / proposalThresholdDivider = percentage needed
    uint public proposalThresholdDivider;
    // The maximum number of individual transactions that can make up a proposal
    uint public proposalMaxOperations;
    // Time period (in blocks) during which the proposal can be voted on
    uint public votingPeriod;
    // Delay (in blocks) that must be waited after a proposal has been added before the voting phase begins
    uint public votingDelay;

    // Time period in which the transaction must be executed after the delay expires
    uint public gracePeriod;
    // Delay that must be waited after the voting period has ended and a proposal has been queued before it can be executed
    uint public delay;

    event NewQuorumVotesDivider(uint indexed newQuorumVotesDivider);
    event NewProposalThresholdDivider(uint indexed newProposalThresholdDivider);
    event NewProposalMaxOperations(uint indexed newProposalMaxOperations);
    event NewVotingPeriod(uint indexed newVotingPeriod);
    event NewVotingDelay(uint indexed newVotingDelay);

    event NewGracePeriod(uint indexed newGracePeriod);
    event NewDelay(uint indexed newDelay);

    constructor () public {
        quorumVotesDivider = 16; // 62.5%
        proposalThresholdDivider = 2000; // 0.5%
        proposalMaxOperations = 10;
        votingPeriod = 17280;
        votingDelay = 1;

        gracePeriod = 14 days;
        delay = 2 days;
    }

    function setQuorumVotesDivider(uint _quorumVotesDivider) external onlyOwner {
        quorumVotesDivider = _quorumVotesDivider;
        emit NewQuorumVotesDivider(_quorumVotesDivider);
    }
    function setProposalThresholdDivider(uint _proposalThresholdDivider) external onlyOwner {
        proposalThresholdDivider = _proposalThresholdDivider;
        emit NewProposalThresholdDivider(_proposalThresholdDivider);
    }
    function setProposalMaxOperations(uint _proposalMaxOperations) external onlyOwner {
        proposalMaxOperations = _proposalMaxOperations;
        emit NewProposalMaxOperations(_proposalMaxOperations);
    }
    function setVotingPeriod(uint _votingPeriod) external onlyOwner {
        votingPeriod = _votingPeriod;
        emit NewVotingPeriod(_votingPeriod);
    }
    function setVotingDelay(uint _votingDelay) external onlyOwner {
        votingDelay = _votingDelay;
        emit NewVotingDelay(_votingDelay);
    }

    function setGracePeriod(uint _gracePeriod) external onlyOwner {
        gracePeriod = _gracePeriod;
        emit NewGracePeriod(_gracePeriod);
    }
    function setDelay(uint _delay) external onlyOwner {
        require(_delay >= MINIMUM_DELAY, "TimeLock::setDelay: Delay must exceed minimum delay.");
        require(_delay <= MAXIMUM_DELAY, "TimeLock::setDelay: Delay must not exceed maximum delay.");
        delay = _delay;
        emit NewDelay(_delay);
    }
}