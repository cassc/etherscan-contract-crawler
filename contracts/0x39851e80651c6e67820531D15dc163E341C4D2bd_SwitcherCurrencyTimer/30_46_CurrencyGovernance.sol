// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./TrustedNodes.sol";
import "../../policy/Policy.sol";
import "../../policy/PolicedUtils.sol";
import "../../currency/IECO.sol";
import "./RandomInflation.sol";
import "../../utils/TimeUtils.sol";
import "../../VDF/VDFVerifier.sol";

/** @title Inflation/Deflation Process
 *
 * This contract oversees the voting on the currency inflation/deflation process.
 * Trusted nodes vote on a policy that is implemented the following generation
 * to manage the relative price of Eco tokens.
 */
contract CurrencyGovernance is PolicedUtils, TimeUtils, Pausable {
    enum Stage {
        Propose,
        Commit,
        Reveal,
        Compute,
        Finished
    }

    // tracks the progress of the contract
    Stage public currentStage;

    // data structure for monetary policy proposals
    struct GovernanceProposal {
        // random inflation recipients
        uint256 numberOfRecipients;
        // amount of weico recieved by each random inflation recipient
        uint256 randomInflationReward;
        // duration in seconds
        uint256 lockupDuration;
        // lockup interest as a 9 digit fixed point number
        uint256 lockupInterest;
        // multiplier for linear inflation as an 18 digit fixed point number
        uint256 inflationMultiplier;
        // to store a link to more information
        string description;
    }

    struct Vote {
        // the proposal being voted for
        address proposal;
        // the score of this proposal within the ballot, min recorded score is one
        // to get a score of zero, an item must be unscored
        uint256 score;
    }

    // timescales
    uint256 public constant PROPOSAL_TIME = 10 days;
    uint256 public constant VOTING_TIME = 3 days;
    uint256 public constant REVEAL_TIME = 1 days;

    // timestamps for the above periods
    uint256 public proposalEnds;
    uint256 public votingEnds;
    uint256 public revealEnds;

    uint256 public constant IDEMPOTENT_INFLATION_MULTIPLIER = 1e18;

    // max length of description field
    uint256 public constant MAX_DATA = 160;

    // mapping of proposing trustee addresses to their submitted proposals
    mapping(address => GovernanceProposal) public proposals;
    // mapping of trustee addresses to their hash commits for voting
    mapping(address => bytes32) public commitments;
    // mapping of proposals (indexed by the submitting trustee) to their voting score, accumulated during reveal
    mapping(address => uint256) public score;

    // used to track the leading proposal during the vote totalling
    address public leader;
    // used to denote the winning proposal when the vote is finalized
    address public winner;

    // address that can pause currency governance
    address public pauser;

    // emitted when a proposal is submitted to track the values
    event ProposalCreation(
        address indexed trusteeAddress,
        uint256 _numberOfRecipients,
        uint256 _randomInflationReward,
        uint256 _lockupDuration,
        uint256 _lockupInterest,
        uint256 _inflationMultiplier,
        string _description
    );

    // emitted when a trustee retracts their proposal
    event ProposalRetraction(address indexed trustee);

    /** Fired when the voting stage begins.
     * Triggered by updateStage().
     */
    event VoteStart();

    /** Fired when a trustee casts a vote.
     */
    event VoteCast(address indexed trustee);

    /** Fired when the reveal stage begins.
     * Triggered by updateStage().
     */
    event RevealStart();

    /** Fired when a vote is revealed, to create a voting history for all
     * participants. Records the voter, as well as all of the parameters of
     * the vote cast.
     */
    event VoteReveal(address indexed voter, Vote[] votes);

    /** Fired when vote results are computed, creating a permanent record of
     * vote outcomes.
     */
    event VoteResult(address indexed winner);

    /**
     * @notice event indicating the pauser was updated
     * @param pauser The new pauser
     */
    event PauserAssignment(address indexed pauser);

    modifier onlyPauser() {
        require(msg.sender == pauser, "CurrencyGovernance: not pauser");
        _;
    }

    modifier atStage(Stage _stage) {
        updateStage();
        require(
            currentStage == _stage,
            "This call is not allowed at this stage"
        );
        _;
    }

    function updateStage() public {
        uint256 time = getTime();
        if (currentStage == Stage.Propose && time >= proposalEnds) {
            currentStage = Stage.Commit;
            emit VoteStart();
        }
        if (currentStage == Stage.Commit && time >= votingEnds) {
            currentStage = Stage.Reveal;
            emit RevealStart();
        }
        if (currentStage == Stage.Reveal && time >= revealEnds) {
            currentStage = Stage.Compute;
        }
    }

    constructor(Policy _policy, address _initialPauser) PolicedUtils(_policy) {
        pauser = _initialPauser;
        emit PauserAssignment(_initialPauser);
    }

    /** Restrict access to trusted nodes only.
     */
    modifier onlyTrusted() {
        require(
            getTrustedNodes().isTrusted(msg.sender),
            "Only trusted nodes can call this method"
        );
        _;
    }

    function propose(
        uint256 _numberOfRecipients,
        uint256 _randomInflationReward,
        uint256 _lockupDuration,
        uint256 _lockupInterest,
        uint256 _inflationMultiplier,
        string calldata _description
    ) external onlyTrusted atStage(Stage.Propose) {
        require(
            _inflationMultiplier > 0,
            "Inflation multiplier cannot be zero"
        );
        require(
            // didn't choose this number for any particular reason
            uint256(bytes(_description).length) <= MAX_DATA,
            "Description is too long"
        );

        GovernanceProposal storage p = proposals[msg.sender];
        p.numberOfRecipients = _numberOfRecipients;
        p.randomInflationReward = _randomInflationReward;
        p.lockupDuration = _lockupDuration;
        p.lockupInterest = _lockupInterest;
        p.inflationMultiplier = _inflationMultiplier;
        p.description = _description;

        emit ProposalCreation(
            msg.sender,
            _numberOfRecipients,
            _randomInflationReward,
            _lockupDuration,
            _lockupInterest,
            _inflationMultiplier,
            _description
        );
    }

    function unpropose() external atStage(Stage.Propose) {
        require(
            proposals[msg.sender].inflationMultiplier != 0,
            "You do not have a proposal to retract"
        );
        delete proposals[msg.sender];
        emit ProposalRetraction(msg.sender);
    }

    function commit(bytes32 _commitment)
        external
        onlyTrusted
        atStage(Stage.Commit)
    {
        commitments[msg.sender] = _commitment;
        emit VoteCast(msg.sender);
    }

    function reveal(bytes32 _seed, Vote[] calldata _votes)
        external
        atStage(Stage.Reveal)
    {
        uint256 numVotes = _votes.length;
        require(numVotes > 0, "Invalid vote, cannot vote empty");
        require(
            commitments[msg.sender] != bytes32(0),
            "Invalid vote, no unrevealed commitment exists"
        );
        require(
            keccak256(abi.encode(_seed, msg.sender, _votes)) ==
                commitments[msg.sender],
            "Invalid vote, commitment mismatch"
        );

        delete commitments[msg.sender];

        // remove the trustee's default vote
        score[address(0)] -= 1;

        // use memory vars to store and track the changes of the leader
        address priorLeader = leader;
        address leaderTracker = priorLeader;
        uint256 leaderRankTracker = 0;

        /**
         * by setting this to 1, the code can skip checking _score != 0
         */
        uint256 scoreDuplicateCheck = 1;

        for (uint256 i = 0; i < numVotes; ++i) {
            Vote memory v = _votes[i];
            address _proposal = v.proposal;
            uint256 _score = v.score;

            require(
                proposals[_proposal].inflationMultiplier > 0,
                "Invalid vote, missing proposal"
            );
            require(
                i == 0 || _votes[i - 1].proposal < _proposal,
                "Invalid vote, proposals not in increasing order"
            );
            require(
                _score <= numVotes,
                "Invalid vote, proposal score out of bounds"
            );
            require(
                scoreDuplicateCheck & (1 << _score) == 0,
                "Invalid vote, duplicate score"
            );

            scoreDuplicateCheck += 1 << _score;

            score[_proposal] += _score;
            if (score[_proposal] > score[leaderTracker]) {
                leaderTracker = _proposal;
                leaderRankTracker = _score;
            } else if (score[_proposal] == score[leaderTracker]) {
                if (_score > leaderRankTracker) {
                    leaderTracker = _proposal;
                    leaderRankTracker = _score;
                }
            }
        }

        // only changes the leader if the new leader is of greater score
        if (
            leaderTracker != priorLeader &&
            score[leaderTracker] > score[priorLeader]
        ) {
            leader = leaderTracker;
        }

        // record the trustee's vote for compensation purposes
        getTrustedNodes().recordVote(msg.sender);

        emit VoteReveal(msg.sender, _votes);
    }

    function compute() external atStage(Stage.Compute) {
        // if paused then the default policy automatically wins
        if (!paused()) {
            winner = leader;
        }

        currentStage = Stage.Finished;

        emit VoteResult(winner);
    }

    /** Initialize the storage context using parameters copied from the
     * original contract (provided as _self).
     *
     * Can only be called once, during proxy initialization.
     *
     * @param _self The original contract address.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
        TimedPolicies timedPolicies = TimedPolicies(
            policyFor(ID_TIMED_POLICIES)
        );
        proposalEnds =
            timedPolicies.generationEnd() -
            MIN_GENERATION_DURATION +
            PROPOSAL_TIME;
        votingEnds = proposalEnds + VOTING_TIME;
        revealEnds = votingEnds + REVEAL_TIME;

        // should not emit an event
        pauser = CurrencyGovernance(_self).pauser();

        GovernanceProposal storage p = proposals[address(0)];
        p.inflationMultiplier = IDEMPOTENT_INFLATION_MULTIPLIER;

        // sets the default votes for the default proposal
        score[address(0)] = getTrustedNodes().numTrustees();
    }

    function getTrustedNodes() private view returns (TrustedNodes) {
        return TrustedNodes(policyFor(ID_TRUSTED_NODES));
    }

    /**
     * @notice set the given address as the pauser
     * @param _pauser The address that can pause this token
     * @dev only the roleAdmin can call this function
     */
    function setPauser(address _pauser) public onlyPolicy {
        pauser = _pauser;
        emit PauserAssignment(_pauser);
    }

    /**
     * @notice pauses transfers of this token
     * @dev only callable by the pauser
     */
    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @notice unpauses transfers of this token
     * @dev only callable by the pauser
     */
    function unpause() external onlyPauser {
        _unpause();
    }
}