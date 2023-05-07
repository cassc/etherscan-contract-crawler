// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/Policy.sol";
import "./proposals/Proposal.sol";
import "../../policy/PolicedUtils.sol";
import "../../utils/TimeUtils.sol";
import "./VotingPower.sol";
import "../../currency/ECO.sol";
import "../../currency/ECOx.sol";

/** @title PolicyVotes
 * This implements the voting and implementation phases of the policy decision process.
 * Open stake based voting is used for the voting phase.
 */
contract PolicyVotes is VotingPower, TimeUtils {
    /** The proposal being voted on */
    Proposal public proposal;

    /* The proposer of the proposal being voted on */
    address public proposer;

    /** The stake an the yes votes of an address on a proposal
     */
    struct VotePartial {
        uint256 stake;
        uint256 yesVotes;
    }

    /** The voting power that a user has based on their stake and
     *  the portion that they have voted yes with
     */
    mapping(address => VotePartial) public votePartials;

    /** Total currency staked in all ongoing votes in basic unit of 10^{-18} ECO (weico).
     */
    uint256 public totalStake;

    /** Total revealed positive stake in basic unit of 10^{-18} ECO (weico).
     */
    uint256 public yesStake;

    /** The length of the commit portion of the voting phase.
     */
    uint256 public constant VOTE_TIME = 3 days;

    /** The delay on a plurality win
     */
    uint256 public constant ENACTION_DELAY = 1 days;

    /** The timestamp at which the commit portion of the voting phase ends.
     */
    uint256 public voteEnds;

    /** Vote result */
    enum Result {
        Accepted,
        Rejected,
        Failed
    }

    /** Event emitted when the vote outcome is known.
     */
    event VoteCompletion(Result indexed result);

    /** Event emitted when a vote is submitted.
     * simple votes have the address's voting power as votesYes or votesNo, depending on the vote
     * split votes show the split and votesYes + votesNo might be less than the address's voting power
     */
    event PolicyVote(address indexed voter, uint256 votesYes, uint256 votesNo);

    /** The store block number to use when checking account balances for staking.
     */
    uint256 public blockNumber;

    /** This constructor just passes the call to the super constructor
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(Policy _policy, ECO _ecoAddr) VotingPower(_policy, _ecoAddr) {}

    /** Submit your yes/no support
     *
     * Shows whether or not your voting power supports or does not support the vote
     *
     * Note Not voting is not equivalent to voting no. Percentage of voted support,
     * not percentage of total voting power is used to determine the win.
     *
     * @param _vote The vote for the proposal
     */
    function vote(bool _vote) external {
        require(
            getTime() < voteEnds,
            "Votes can only be recorded during the voting period"
        );

        uint256 _amount = votingPower(msg.sender, blockNumber);

        require(
            _amount > 0,
            "Voters must have held tokens before this voting cycle"
        );

        VotePartial storage vpower = votePartials[msg.sender];
        uint256 _oldStake = vpower.stake;
        uint256 _oldYesVotes = vpower.yesVotes;
        bool _prevVote = _oldYesVotes != 0;

        if (_oldStake != 0) {
            require(
                _prevVote != _vote ||
                    _oldStake != _amount ||
                    (_vote && (_oldYesVotes != _amount)),
                "Your vote has already been recorded"
            );

            if (_prevVote) {
                yesStake -= _oldYesVotes;
                vpower.yesVotes = 0;
            }
        }

        vpower.stake = _amount;
        totalStake = totalStake + _amount - _oldStake;

        if (_vote) {
            yesStake += _amount;
            vpower.yesVotes = _amount;

            emit PolicyVote(msg.sender, _amount, 0);
        } else {
            emit PolicyVote(msg.sender, 0, _amount);
        }
    }

    /** Submit a mixed vote of yes/no support
     *
     * Useful for contracts that wish to vote for an agregate of users
     *
     * Note As not voting is not equivalent to voting no it matters recording the no votes
     * The total amount of votes in favor is relevant for early enaction and the total percentage
     * of voting power that voted is necessary for determining a winner.
     *
     * Note As this is designed for contracts, the onus is on the contract designer to correctly
     * understand and take responsibility for its input parameters. The only check is to stop
     * someone from voting with more power than they have.
     *
     * @param _votesYes The amount of votes in favor of the proposal
     * @param _votesNo The amount of votes against the proposal
     */
    function voteSplit(uint256 _votesYes, uint256 _votesNo) external {
        require(
            getTime() < voteEnds,
            "Votes can only be recorded during the voting period"
        );

        uint256 _amount = votingPower(msg.sender, blockNumber);

        require(
            _amount > 0,
            "Voters must have held tokens before this voting cycle"
        );

        uint256 _totalVotes = _votesYes + _votesNo;

        require(
            _amount >= _totalVotes,
            "Your voting power is less than submitted yes + no votes"
        );

        VotePartial storage vpower = votePartials[msg.sender];
        uint256 _oldStake = vpower.stake;
        uint256 _oldYesVotes = vpower.yesVotes;

        if (_oldYesVotes > 0) {
            yesStake -= _oldYesVotes;
        }

        vpower.yesVotes = _votesYes;
        yesStake += _votesYes;

        vpower.stake = _totalVotes;
        totalStake = totalStake + _totalVotes - _oldStake;

        emit PolicyVote(msg.sender, _votesYes, _votesNo);
    }

    /** Initialize a cloned/proxied copy of this contract.
     *
     * @param _self The original contract, to provide access to storage data.
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
    }

    /** Configure the proposals that are part of this voting cycle and start
     * the lockup period.
     *
     * This also fixes the end times of each subsequent phase.
     *
     * This can only be called once, and should be called atomically with
     * instantiation.
     *
     * @param _proposal The proposal to vote on.
     */
    function configure(
        Proposal _proposal,
        address _proposer,
        uint256 _cutoffBlockNumber,
        uint256 _totalECOxSnapshot,
        uint256 _excludedVotingPower
    ) external {
        require(voteEnds == 0, "This instance has already been configured");

        voteEnds = getTime() + VOTE_TIME;
        blockNumber = _cutoffBlockNumber;
        totalECOxSnapshot = _totalECOxSnapshot;
        excludedVotingPower = _excludedVotingPower;

        proposal = _proposal;
        proposer = _proposer;
    }

    /** Execute the proposal if it has enough support.
     *
     * Can only be called after the voting and the delay phase,
     * or after the point that at least 50% of the total voting power
     * has voted in favor of the proposal.
     *
     * If the proposal has been accepted, it will be enacted by
     * calling the `enacted` functions using `delegatecall`
     * from the root policy.
     */
    function execute() external {
        uint256 _total = totalVotingPower(blockNumber);

        Result _res;

        if (2 * yesStake < _total) {
            require(
                getTime() > voteEnds + ENACTION_DELAY,
                "Majority support required for early enaction"
            );
        }

        require(
            policyFor(ID_POLICY_VOTES) == address(this),
            "This contract no longer has authorization to enact the vote"
        );

        if (totalStake == 0) {
            // Nobody voted
            _res = Result.Failed;
        } else if (2 * yesStake < totalStake) {
            // Not enough yes votes
            _res = Result.Rejected;
        } else {
            // Vote passed
            _res = Result.Accepted;

            //Enact the policy
            policy.internalCommand(address(proposal), ID_POLICY_VOTES);
        }

        emit VoteCompletion(_res);
        policy.removeSelf(ID_POLICY_VOTES);
    }
}