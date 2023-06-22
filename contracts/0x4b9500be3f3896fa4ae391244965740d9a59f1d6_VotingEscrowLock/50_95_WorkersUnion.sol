//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../core/dividend/interfaces/IDividendPool.sol";
import "../../core/governance/Governed.sol";
import "../../core/governance/TimelockedGovernance.sol";
import "../../core/governance/interfaces/IVoteCounter.sol";
import "../../core/governance/interfaces/IWorkersUnion.sol";
import "../../utils/Sqrt.sol";

/**
 * @notice referenced openzeppelin's TimelockController.sol
 */
contract WorkersUnion is Pausable, Governed, Initializable, IWorkersUnion {
    using SafeMath for uint256;
    using Sqrt for uint256;

    bytes32 public constant NO_DEPENDENCY = bytes32(0);

    uint256 private _launch;
    VotingRule private _votingRule;
    mapping(bytes32 => Proposal) private _proposals;

    event TxProposed(
        bytes32 indexed txHash,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 start,
        uint256 end
    );

    event BatchTxProposed(
        bytes32 indexed txHash,
        address[] target,
        uint256[] value,
        bytes[] data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 start,
        uint256 end
    );

    event Vote(bytes32 txHash, address voter, bool forVote);
    event VoteUpdated(bytes32 txHash, uint256 forVotes, uint256 againsVotes);

    function initialize(
        address voteCounter,
        address timelockGov,
        uint256 launchDelay
    ) public initializer {
        _votingRule = VotingRule(
            1 days, // minimum pending for vote
            1 weeks, // maximum pending for vote
            1 weeks, // minimum voting period
            4 weeks, // maximum voting period
            0 gwei, // minimum votes for proposing
            0 gwei, // minimum votes
            voteCounter
        );
        Governed.initialize(timelockGov);
        _pause();
        _launch = block.timestamp.add(launchDelay);
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    function launch() public override {
        require(block.timestamp >= _launch, "Wait a bit please.");
        _unpause();
    }

    function changeVotingRule(
        uint256 minimumPendingPeriod,
        uint256 maximumPendingPeriod,
        uint256 minimumVotingPeriod,
        uint256 maximumVotingPeriod,
        uint256 minimumVotesForProposing,
        uint256 minimumVotes,
        address voteCounter
    ) public override governed {
        uint256 totalVotes = IVoteCounter(voteCounter).getTotalVotes();

        require(minimumPendingPeriod <= maximumPendingPeriod, "invalid arg");
        require(minimumVotingPeriod <= maximumVotingPeriod, "invalid arg");
        require(minimumVotingPeriod >= 1 days, "too short");
        require(minimumPendingPeriod >= 1 days, "too short");
        require(maximumVotingPeriod <= 30 days, "too long");
        require(maximumPendingPeriod <= 30 days, "too long");
        require(
            minimumVotesForProposing <= totalVotes.div(10),
            "too large number"
        );
        require(minimumVotes <= totalVotes.div(2), "too large number");
        require(address(voteCounter) != address(0), "null address");
        _votingRule = VotingRule(
            minimumPendingPeriod,
            maximumPendingPeriod,
            minimumVotingPeriod,
            maximumVotingPeriod,
            minimumVotesForProposing,
            minimumVotes,
            voteCounter
        );
    }

    function proposeTx(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 startsIn,
        uint256 votingPeriod
    ) public override {
        _beforePropose(startsIn, votingPeriod);
        bytes32 txHash =
            _timelock().hashOperation(target, value, data, predecessor, salt);
        _propose(txHash, startsIn, votingPeriod);
        emit TxProposed(
            txHash,
            target,
            value,
            data,
            predecessor,
            salt,
            block.timestamp + startsIn,
            block.timestamp + startsIn + votingPeriod
        );
    }

    function proposeBatchTx(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 startsIn,
        uint256 votingPeriod
    ) public override whenNotPaused {
        _beforePropose(startsIn, votingPeriod);
        bytes32 txHash =
            _timelock().hashOperationBatch(
                target,
                value,
                data,
                predecessor,
                salt
            );
        _propose(txHash, startsIn, votingPeriod);
        emit BatchTxProposed(
            txHash,
            target,
            value,
            data,
            predecessor,
            salt,
            block.timestamp + startsIn,
            block.timestamp + startsIn + votingPeriod
        );
    }

    /**
     * @notice Should use vote(bytes32, uint256[], bool) when too many voting rights are delegated to avoid out of gas.
     */
    function vote(bytes32 txHash, bool agree) public override {
        uint256[] memory votingRights =
            IVoteCounter(_votingRule.voteCounter).votingRights(msg.sender);
        manualVote(txHash, votingRights, agree);
    }

    /**
     * @notice The voting will be updated if the voter already voted. Please
     *      note that the voting power may change by the locking period or others.
     *      To have more detail information about how voting power is computed,
     *      Please go to the QVCounter.sol.
     */
    function manualVote(
        bytes32 txHash,
        uint256[] memory rightIds,
        bool agree
    ) public override {
        Proposal storage proposal = _proposals[txHash];
        uint256 timestamp = proposal.start;
        require(
            getVotingStatus(txHash) == VotingState.Voting,
            "Not in the voting period"
        );
        uint256 totalForVotes = proposal.totalForVotes;
        uint256 totalAgainstVotes = proposal.totalAgainstVotes;
        for (uint256 i = 0; i < rightIds.length; i++) {
            uint256 id = rightIds[i];
            require(
                IVoteCounter(_votingRule.voteCounter).voterOf(id) == msg.sender,
                "not the voting right owner"
            );
            uint256 prevForVotes = proposal.forVotes[id];
            uint256 prevAgainstVotes = proposal.againstVotes[id];
            uint256 votes =
                IVoteCounter(_votingRule.voteCounter).getVotes(id, timestamp);
            proposal.forVotes[id] = agree ? votes : 0;
            proposal.againstVotes[id] = agree ? 0 : votes;
            totalForVotes = totalForVotes.add(agree ? votes : 0).sub(
                prevForVotes
            );
            totalAgainstVotes = totalAgainstVotes.add(agree ? 0 : votes).sub(
                prevAgainstVotes
            );
        }
        proposal.totalForVotes = totalForVotes;
        proposal.totalAgainstVotes = totalAgainstVotes;
        emit Vote(txHash, msg.sender, agree);
        emit VoteUpdated(txHash, totalForVotes, totalAgainstVotes);
    }

    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public override {
        bytes32 txHash =
            _timelock().hashOperation(target, value, data, predecessor, salt);
        require(
            getVotingStatus(txHash) == VotingState.Passed,
            "vote is not passed"
        );
        _timelock().forceSchedule(
            target,
            value,
            data,
            predecessor,
            salt,
            _timelock().getMinDelay()
        );
    }

    function scheduleBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public override {
        bytes32 txHash =
            _timelock().hashOperationBatch(
                target,
                value,
                data,
                predecessor,
                salt
            );
        require(
            getVotingStatus(txHash) == VotingState.Passed,
            "vote is not passed"
        );
        _timelock().forceScheduleBatch(
            target,
            value,
            data,
            predecessor,
            salt,
            _timelock().getMinDelay()
        );
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override {
        bytes32 txHash =
            _timelock().hashOperation(target, value, data, predecessor, salt);
        require(
            getVotingStatus(txHash) == VotingState.Passed,
            "vote is not passed"
        );
        _timelock().execute{value: value}(
            target,
            value,
            data,
            predecessor,
            salt
        );
    }

    function executeBatch(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable override {
        require(target.length == value.length, "length mismatch");
        require(target.length == data.length, "length mismatch");
        bytes32 txHash =
            _timelock().hashOperationBatch(
                target,
                value,
                data,
                predecessor,
                salt
            );
        require(
            getVotingStatus(txHash) == VotingState.Passed,
            "vote is not passed"
        );
        uint256 valueSum = 0;
        for (uint256 i = 0; i < value.length; i++) {
            valueSum = valueSum.add(value[i]);
        }
        _timelock().executeBatch{value: valueSum}(
            target,
            value,
            data,
            predecessor,
            salt
        );
    }

    function votingRule() public view override returns (VotingRule memory) {
        return _votingRule;
    }

    function getVotingStatus(bytes32 txHash)
        public
        view
        override
        returns (VotingState)
    {
        Proposal storage proposal = _proposals[txHash];
        require(proposal.start != 0, "Not an existing proposal");
        if (block.timestamp < proposal.start) return VotingState.Pending;
        else if (block.timestamp <= proposal.end) return VotingState.Voting;
        else if (_timelock().isOperationDone(txHash))
            return VotingState.Executed;
        else if (proposal.totalForVotes < _votingRule.minimumVotes)
            return VotingState.Rejected;
        else if (proposal.totalForVotes > proposal.totalAgainstVotes)
            return VotingState.Passed;
        else return VotingState.Rejected;
    }

    function getVotesFor(address account, bytes32 txHash)
        public
        view
        override
        returns (uint256)
    {
        uint256 timestamp = _proposals[txHash].start;
        return getVotesAt(account, timestamp);
    }

    function getVotesAt(address account, uint256 timestamp)
        public
        view
        override
        returns (uint256)
    {
        uint256[] memory votingRights =
            IVoteCounter(_votingRule.voteCounter).votingRights(account);
        uint256 votes;
        for (uint256 i = 0; i < votingRights.length; i++) {
            votes = votes.add(
                IVoteCounter(_votingRule.voteCounter).getVotes(
                    votingRights[i],
                    timestamp
                )
            );
        }
        return votes;
    }

    function proposals(bytes32 proposalHash)
        public
        view
        override
        returns (
            address proposer,
            uint256 start,
            uint256 end,
            uint256 totalForVotes,
            uint256 totalAgainstVotes
        )
    {
        Proposal storage proposal = _proposals[proposalHash];
        return (
            proposal.proposer,
            proposal.start,
            proposal.end,
            proposal.totalForVotes,
            proposal.totalAgainstVotes
        );
    }

    function _propose(
        bytes32 txHash,
        uint256 startsIn,
        uint256 votingPeriod
    ) private whenNotPaused {
        Proposal storage proposal = _proposals[txHash];
        require(proposal.proposer == address(0));
        proposal.proposer = msg.sender;
        proposal.start = block.timestamp + startsIn;
        proposal.end = proposal.start + votingPeriod;
    }

    function _beforePropose(uint256 startsIn, uint256 votingPeriod)
        private
        view
    {
        uint256 votes = getVotesAt(msg.sender, block.timestamp);
        require(
            _votingRule.minimumVotesForProposing <= votes,
            "Not enough votes for proposing."
        );
        require(
            _votingRule.minimumPending <= startsIn,
            "Pending period is too short."
        );
        require(
            startsIn <= _votingRule.maximumPending,
            "Pending period is too long."
        );
        require(
            _votingRule.minimumVotingPeriod <= votingPeriod,
            "Voting period is too short."
        );
        require(
            votingPeriod <= _votingRule.maximumVotingPeriod,
            "Voting period is too long."
        );
    }

    function _timelock() internal view returns (TimelockedGovernance) {
        return TimelockedGovernance(payable(_gov));
    }
}