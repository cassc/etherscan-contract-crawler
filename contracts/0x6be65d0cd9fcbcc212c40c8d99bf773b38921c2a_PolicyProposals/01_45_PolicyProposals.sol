// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/Policy.sol";
import "../../currency/IECO.sol";
import "../../policy/PolicedUtils.sol";
import "./proposals/Proposal.sol";
import "./PolicyVotes.sol";
import "../TimedPolicies.sol";
import "./VotingPower.sol";
import "../../utils/TimeUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title PolicyProposals
 * `PolicyProposals` oversees the proposals phase of the policy decision
 * process. Proposals can be submitted by anyone willing to put forth funds, and
 * submitted proposals can be supported by anyone
 *
 * First, during the proposals portion of the proposals phase, proposals can be
 * submitted (for a fee). This is parallelized with a signal voting process where
 * support can be distributed and redistributed to proposals after they are submitted.
 *
 * A proposal that makes it to support above 30% of the total possible support ends this
 * phase and starts a vote.
 */
contract PolicyProposals is VotingPower, TimeUtils {
    /** The data tracked for a proposal in the process.
     */
    struct PropData {
        // the returnable data
        PropMetadata metadata;
        // A record of which addresses have already staked in support of the proposal
        mapping(address => bool) staked;
    }

    /** The submitted data for a proposal submitted to the process.
     */
    struct PropMetadata {
        /* The address of the proposing account.
         */
        address proposer;
        /* The address of the proposal contract.
         */
        Proposal proposal;
        /* The amount of tokens staked in support of this proposal.
         */
        uint256 totalStake;
        /* Flag to mark if a pause caused the fee to be waived.
         */
        bool feeWaived;
    }

    /** The set of proposals under consideration.
     * maps from addresses of proposals to structs containing with info and
     * the staking data (structs defined above)
     */
    mapping(Proposal => PropData) public proposals;

    /** The total number of proposals made.
     */
    uint256 public totalProposals;

    /** The duration of the proposal portion of the proposal phase.
     */
    uint256 public constant PROPOSAL_TIME = 9 days + 16 hours;

    /** Whether or not a winning proposal has been selected
     */
    bool public proposalSelected;

    /** Selected proposal awaiting configuration before voting
     */
    Proposal public proposalToConfigure;

    /** The minimum cost to register a proposal.
     */
    uint256 public constant COST_REGISTER = 10000e18;

    /** The amount refunded if a proposal does not get selected.
     */
    uint256 public constant REFUND_IF_LOST = 5000e18;

    /** The percentage of total voting power required to push to a vote.
     */
    uint256 public constant SUPPORT_THRESHOLD = 15;

    /** The divisor for the above constant, tracks the digits of precision.
     */
    uint256 public constant SUPPORT_THRESHOLD_DIVISOR = 100;

    /** The total voting value against which to compare for the threshold
     * This is a fixed digit number with 2 decimal digits
     * see SUPPORT_THRESHOLD_DIVISOR variable
     */
    uint256 public totalVotingThreshold;

    /** The time at which the proposal portion of the proposals phase ends.
     */
    uint256 public proposalEnds;

    /** The block number of the balance stores to use for staking in
     * support of a proposal.
     */
    uint256 public blockNumber;

    /** The address of the `PolicyVotes` contract, to be cloned for the voting
     * phase.
     */
    PolicyVotes public policyVotesImpl;

    /** An event indicating a proposal has been proposed
     *
     * @param proposer The address that submitted the Proposal
     * @param proposalAddress The address of the Proposal contract instance that was added
     */
    event Register(address indexed proposer, Proposal indexed proposalAddress);

    /** An event indicating that proposal have been supported by stake.
     *
     * @param supporter The address submitting their support for the proposal
     * @param proposalAddress The address of the Proposal contract instance that was supported
     */
    event Support(address indexed supporter, Proposal indexed proposalAddress);

    /** An event indicating that support has been removed from a proposal.
     *
     * @param unsupporter The address removing their support for the proposal
     * @param proposalAddress The address of the Proposal contract instance that was unsupported
     */
    event Unsupport(
        address indexed unsupporter,
        Proposal indexed proposalAddress
    );

    /** An event indicating a proposal has reached its support threshold
     *
     * @param proposalAddress The address of the Proposal contract instance that reached the threshold.
     */
    event SupportThresholdReached(Proposal indexed proposalAddress);

    /** An event indicating that a proposal has been accepted for voting
     *
     * @param contractAddress The address of the PolicyVotes contract instance.
     */
    event VoteStart(PolicyVotes indexed contractAddress);

    /** An event indicating that proposal fee was partially refunded.
     *
     * @param proposer The address of the proposee which was refunded
     * @param proposalAddress The address of the Proposal instance that was refunded
     */
    event ProposalRefund(
        address indexed proposer,
        Proposal indexed proposalAddress
    );

    /** Construct a new PolicyProposals instance using the provided supervising
     * policy (root) and supporting contracts.
     *
     * @param _policy The address of the root policy contract.
     * @param _policyvotes The address of the contract that will be cloned to
     *                     oversee the voting phase.
     * @param _ecoAddr The address of the ECO token contract.
     */
    constructor(
        Policy _policy,
        PolicyVotes _policyvotes,
        ECO _ecoAddr
    ) VotingPower(_policy, _ecoAddr) {
        require(
            address(_policyvotes) != address(0),
            "Unrecoverable: do not set the _policyvotes as the zero address"
        );
        policyVotesImpl = _policyvotes;
    }

    /** Initialize the storage context using parameters copied from the original
     * contract (provided as _self).
     *
     * Can only be called once, during proxy initialization.
     *
     * @param _self The original contract address.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);

        // implementation addresses are left as mutable for easier governance
        policyVotesImpl = PolicyProposals(_self).policyVotesImpl();
        TimedPolicies timedPolicies = TimedPolicies(
            policyFor(ID_TIMED_POLICIES)
        );
        proposalEnds =
            timedPolicies.generationEnd() -
            MIN_GENERATION_DURATION +
            PROPOSAL_TIME;
        blockNumber = block.number;
    }

    /** Submit a proposal.
     *
     * You must approve the policy proposals contract to withdraw the required
     * fee from your account before calling this.
     *
     * Can only be called during the proposals portion of the proposals phase.
     * Each proposal may only be submitted once.
     *
     * @param _prop The address of the proposal to submit.
     */
    function registerProposal(Proposal _prop) external {
        require(
            address(_prop) != address(0),
            "The proposal address can't be 0"
        );

        require(
            getTime() < proposalEnds && !proposalSelected,
            "Proposals may no longer be registered because the registration period has ended"
        );

        PropMetadata storage _p = proposals[_prop].metadata;

        require(
            address(_p.proposal) == address(0),
            "A proposal may only be registered once"
        );

        _p.proposal = _prop;
        _p.proposer = msg.sender;

        totalProposals++;

        // if eco token is paused, the proposal fee can't be and isn't collected
        if (!ecoToken.paused()) {
            require(
                ecoToken.transferFrom(msg.sender, address(this), COST_REGISTER),
                "The token cost of registration must be approved to transfer prior to calling registerProposal"
            );
        } else {
            _p.feeWaived = true;
        }

        emit Register(msg.sender, _prop);

        // check if totalVotingThreshold still needs to be precomputed
        if (totalVotingThreshold == 0) {
            totalVotingThreshold =
                totalVotingPower(blockNumber) *
                SUPPORT_THRESHOLD;
        }
    }

    /** Stake in support of an existing proposal.
     *
     * Can only be called during the staking portion of the proposals phase.
     *
     * Your voting strength is added to the supporting stake of the proposal.
     *
     * @param _prop The proposal to support.
     */
    function support(Proposal _prop) external {
        require(
            policyFor(ID_POLICY_PROPOSALS) == address(this),
            "Proposal contract no longer active"
        );
        require(!proposalSelected, "A proposal has already been selected");
        require(
            getTime() < proposalEnds,
            "Proposals may no longer be supported because the registration period has ended"
        );

        PropData storage _p = proposals[_prop];
        PropMetadata storage _pMeta = _p.metadata;

        require(
            address(_pMeta.proposal) != address(0),
            "The supported proposal is not registered"
        );
        require(
            !_p.staked[msg.sender],
            "You may not stake in support of a proposal twice"
        );

        uint256 _amount = votingPower(msg.sender, blockNumber);

        require(
            _amount > 0,
            "In order to support a proposal you must stake a non-zero amount of tokens"
        );

        uint256 _totalStake = _pMeta.totalStake + _amount;

        _pMeta.totalStake = _totalStake;
        _p.staked[msg.sender] = true;

        emit Support(msg.sender, _prop);

        if (_totalStake * SUPPORT_THRESHOLD_DIVISOR > totalVotingThreshold) {
            emit SupportThresholdReached(_prop);
            proposalSelected = true;
            proposalToConfigure = _prop;
        }
    }

    function unsupport(Proposal _prop) external {
        require(
            policyFor(ID_POLICY_PROPOSALS) == address(this),
            "Proposal contract no longer active"
        );
        require(!proposalSelected, "A proposal has already been selected");
        require(
            getTime() < proposalEnds,
            "Proposals may no longer be supported because the registration period has ended"
        );

        PropData storage _p = proposals[_prop];

        require(_p.staked[msg.sender], "You have not staked this proposal");

        uint256 _amount = votingPower(msg.sender, blockNumber);
        _p.metadata.totalStake -= _amount;
        _p.staked[msg.sender] = false;

        emit Unsupport(msg.sender, _prop);
    }

    function deployProposalVoting() external {
        require(proposalSelected, "no proposal has been selected");
        Proposal _proposalToConfigure = proposalToConfigure;
        require(
            address(_proposalToConfigure) != address(0),
            "voting has already been deployed"
        );
        address _proposer = proposals[_proposalToConfigure].metadata.proposer;

        delete proposalToConfigure;
        delete proposals[_proposalToConfigure];
        totalProposals--;

        PolicyVotes pv = PolicyVotes(policyVotesImpl.clone());
        pv.configure(
            _proposalToConfigure,
            _proposer,
            blockNumber,
            totalECOxSnapshot,
            excludedVotingPower
        );
        policy.setPolicy(ID_POLICY_VOTES, address(pv), ID_POLICY_PROPOSALS);

        emit VoteStart(pv);
    }

    /** Refund the fee for a proposal that was not selected.
     *
     * Returns a partial refund only, does not work on proposals that are
     * on the ballot for the voting phase, and can only be called after voting
     * been deployed or when the period is over and no vote was selected.
     *
     * @param _prop The proposal to issue a refund for.
     */
    function refund(Proposal _prop) external {
        require(
            (proposalSelected && address(proposalToConfigure) == address(0)) ||
                getTime() > proposalEnds,
            "Refunds may not be distributed until the period is over or voting has started"
        );

        require(
            address(_prop) != address(0),
            "The proposal address can't be 0"
        );

        PropMetadata storage _p = proposals[_prop].metadata;

        require(
            _p.proposal == _prop,
            "The provided proposal address is not valid"
        );

        address receiver = _p.proposer;
        bool _feePaid = !_p.feeWaived;

        delete proposals[_prop];
        totalProposals--;

        // if fee was waived, still delete the proposal, but do not refund
        if (_feePaid) {
            require(
                ecoToken.transfer(receiver, REFUND_IF_LOST),
                "Transfer Failed"
            );
            emit ProposalRefund(receiver, _prop);
        }
    }

    /** Reclaim tokens after end time
     * only callable if all proposals are refunded
     */
    function destruct() external {
        require(
            proposalSelected || getTime() > proposalEnds,
            "The destruct operation can only be performed when the period is over"
        );

        require(totalProposals == 0, "Must refund all missed proposals first");

        policy.removeSelf(ID_POLICY_PROPOSALS);

        require(
            ecoToken.transfer(
                address(policy),
                ecoToken.balanceOf(address(this))
            ),
            "Transfer Failed"
        );
    }

    // configure the total voting power for the vote thresholds
    function configure(uint256 _totalECOxSnapshot, uint256 _excludedVotingPower)
        external
    {
        require(
            totalECOxSnapshot == 0,
            "This instance has already been configured"
        );
        require(_totalECOxSnapshot != 0, "Invalid value for ECOx voting power");

        totalECOxSnapshot = _totalECOxSnapshot;
        excludedVotingPower = _excludedVotingPower;
    }
}