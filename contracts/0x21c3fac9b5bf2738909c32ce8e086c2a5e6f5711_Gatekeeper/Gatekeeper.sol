/**
 *Submitted for verification at Etherscan.io on 2019-08-22
*/

pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;



/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract ParameterStore {
    // EVENTS
    event ProposalCreated(
        uint256 proposalID,
        address indexed proposer,
        uint256 requestID,
        string key,
        bytes32 value,
        bytes metadataHash
    );
    event Initialized();
    event ParameterSet(string name, bytes32 key, bytes32 value);
    event ProposalAccepted(uint256 proposalID, string key, bytes32 value);


    // STATE
    using SafeMath for uint256;

    address owner;
    bool public initialized;
    mapping(bytes32 => bytes32) public params;

    // A proposal to change a value
    struct Proposal {
        address gatekeeper;
        uint256 requestID;
        string key;
        bytes32 value;
        bytes metadataHash;
        bool executed;
    }

    // All submitted proposals
    Proposal[] public proposals;

    // IMPLEMENTATION
    /**
     @dev Initialize a ParameterStore with a set of names and associated values.
     @param _names Names of parameters
     @param _values abi-encoded values to assign them
    */
    constructor(string[] memory _names, bytes32[] memory _values) public {
        owner = msg.sender;
        require(_names.length == _values.length, "All inputs must have the same length");

        for (uint i = 0; i < _names.length; i++) {
            string memory name = _names[i];
            set(name, _values[i]);
        }
    }

    /**
     @dev Initialize the contract, preventing any more changes not made through slate governance
     */
    function init() public {
        require(msg.sender == owner, "Only the owner can initialize the ParameterStore");
        require(initialized == false, "Contract has already been initialized");

        initialized = true;

        // Do not allow initialization unless the gatekeeperAddress is set
        // Check after setting initialized so we can use the getter
        require(getAsAddress("gatekeeperAddress") != address(0), "Missing gatekeeper");

        emit Initialized();
    }

    // GETTERS

    /**
     @dev Get the parameter value associated with the given name.
     @param _name The name of the parameter to get the value for
    */
    function get(string memory _name) public view returns (bytes32 value) {
        require(initialized, "Contract has not yet been initialized");
        return params[keccak256(abi.encodePacked(_name))];
    }

    /**
     @dev Get the parameter value and cast to `uint256`
     @param _name The name of the parameter to get the value for
    */
    function getAsUint(string memory _name) public view returns(uint256) {
        bytes32 value = get(_name);
        return uint256(value);
    }

    /**
     @dev Get the parameter value and cast to `address`
     @param _name The name of the parameter to get the value for
    */
    function getAsAddress(string memory _name) public view returns (address) {
        bytes32 value = get(_name);
        return address(uint256(value));
    }

    // SETTERS
    /**
     @dev Assign the parameter with the given key to the given value.
     @param _name The name of the parameter to be set
     @param _value The abi-encoded value to assign the parameter
    */
    function set(string memory _name, bytes32 _value) private {
        bytes32 key = keccak256(abi.encodePacked(_name));
        params[key] = _value;
        emit ParameterSet(_name, key, _value);
    }

    /**
     @dev Set a parameter before the ParameterStore has been initialized
     @param _name The name of the parameter to set
     @param _value The abi-encoded value to assign the parameter
    */
    function setInitialValue(string memory _name, bytes32 _value) public {
        require(msg.sender == owner, "Only the owner can set initial values");
        require(initialized == false, "Cannot set values after initialization");

        set(_name, _value);
    }

    function _createProposal(Gatekeeper gatekeeper, string memory key, bytes32 value, bytes memory metadataHash) internal returns(uint256) {
        require(metadataHash.length > 0, "metadataHash cannot be empty");

        Proposal memory p = Proposal({
            gatekeeper: address(gatekeeper),
            requestID: 0,
            key: key,
            value: value,
            metadataHash: metadataHash,
            executed: false
        });

        // Request permission from the Gatekeeper and store the proposal data for later.
        // If the request is approved, a user can execute the proposal by providing the
        // proposalID.
        uint requestID = gatekeeper.requestPermission(metadataHash);
        p.requestID = requestID;
        uint proposalID = proposalCount();
        proposals.push(p);

        emit ProposalCreated(proposalID, msg.sender, requestID, key, value, metadataHash);
        return proposalID;
    }

    /**
     @dev Create a proposal to set a value.
     @param key The key to set
     @param value The value to set
     @param metadataHash A reference to metadata describing the proposal
     */
    function createProposal(string calldata key, bytes32 value, bytes calldata metadataHash) external returns(uint256) {
        require(initialized, "Contract has not yet been initialized");

        Gatekeeper gatekeeper = _gatekeeper();
        return _createProposal(gatekeeper, key, value, metadataHash);
    }

    /**
     @dev Create multiple proposals to set values.
     @param keys The keys to set
     @param values The values to set for the keys
     @param metadataHashes Metadata hashes describing the proposals
    */
    function createManyProposals(
        string[] calldata keys,
        bytes32[] calldata values,
        bytes[] calldata metadataHashes
    ) external {
        require(initialized, "Contract has not yet been initialized");
        require(
            keys.length == values.length && values.length == metadataHashes.length,
            "All inputs must have the same length"
        );

        Gatekeeper gatekeeper = _gatekeeper();
        for (uint i = 0; i < keys.length; i++) {
            string memory key = keys[i];
            bytes32 value = values[i];
            bytes memory metadataHash = metadataHashes[i];
            _createProposal(gatekeeper, key, value, metadataHash);
        }
    }

    /**
     @dev Execute a proposal to set a parameter. The proposal must have been included in an
     accepted governance slate.
     @param proposalID The proposal
     */
    function setValue(uint256 proposalID) public returns(bool) {
        require(proposalID < proposalCount(), "Invalid proposalID");
        require(initialized, "Contract has not yet been initialized");

        Proposal memory p = proposals[proposalID];
        Gatekeeper gatekeeper = Gatekeeper(p.gatekeeper);

        require(gatekeeper.hasPermission(p.requestID), "Proposal has not been approved");
        require(p.executed == false, "Proposal already executed");

        proposals[proposalID].executed = true;

        set(p.key, p.value);

        emit ProposalAccepted(proposalID, p.key, p.value);
        return true;
    }

    function proposalCount() public view returns(uint256) {
        return proposals.length;
    }

    function _gatekeeper() private view returns(Gatekeeper) {
        address gatekeeperAddress = getAsAddress("gatekeeperAddress");
        require(gatekeeperAddress != address(0), "Missing gatekeeper");
        return Gatekeeper(gatekeeperAddress);
    }
}

/**
 * @title Donation receiver interface
 * @dev Contracts (like the TokenCapacitor) that can receive donations
 */
interface IDonationReceiver {
    event Donation(address indexed payer, address indexed donor, uint numTokens, bytes metadataHash);

    function donate(address donor, uint tokens, bytes calldata metadataHash) external returns(bool);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Gatekeeper {
    // EVENTS
    event PermissionRequested(
        uint256 indexed epochNumber,
        address indexed resource,
        uint requestID,
        bytes metadataHash
    );
    event SlateCreated(uint slateID, address indexed recommender, uint[] requestIDs, bytes metadataHash);
    event SlateStaked(uint slateID, address indexed staker, uint numTokens);
    event VotingTokensDeposited(address indexed voter, uint numTokens);
    event VotingTokensWithdrawn(address indexed voter, uint numTokens);
    event VotingRightsDelegated(address indexed voter, address delegate);
    event BallotCommitted(
        uint indexed epochNumber,
        address indexed committer,
        address indexed voter,
        uint numTokens,
        bytes32 commitHash
    );
    event BallotRevealed(uint indexed epochNumber, address indexed voter, uint numTokens);
    event ContestAutomaticallyFinalized(
        uint256 indexed epochNumber,
        address indexed resource,
        uint256 winningSlate
    );
    event ContestFinalizedWithoutWinner(uint indexed epochNumber, address indexed resource);
    event VoteFinalized(
        uint indexed epochNumber,
        address indexed resource,
        uint winningSlate,
        uint winnerVotes,
        uint totalVotes
    );
    event VoteFailed(
        uint indexed epochNumber,
        address indexed resource,
        uint leadingSlate,
        uint leaderVotes,
        uint runnerUpSlate,
        uint runnerUpVotes,
        uint totalVotes
    );
    event RunoffFinalized(
        uint indexed epochNumber,
        address indexed resource,
        uint winningSlate,
        uint winnerVotes,
        uint losingSlate,
        uint loserVotes
    );
    event StakeWithdrawn(uint slateID, address indexed staker, uint numTokens);

    // STATE
    using SafeMath for uint256;

    uint constant ONE_WEEK = 604800;

    // The timestamp of the start of the first epoch
    uint public startTime;
    uint public constant EPOCH_LENGTH = ONE_WEEK * 13;
    uint public constant SLATE_SUBMISSION_PERIOD_START = ONE_WEEK;
    uint public constant COMMIT_PERIOD_START = ONE_WEEK * 11;
    uint public constant REVEAL_PERIOD_START = ONE_WEEK * 12;

    // Parameters
    ParameterStore public parameters;

    // Associated token
    IERC20 public token;

    // Requests
    struct Request {
        bytes metadataHash;
        // The resource (contract) the permission is being requested for
        address resource;
        bool approved;
        uint expirationTime;
        uint epochNumber;
    }

    // The requests made to the Gatekeeper.
    Request[] public requests;

    // Voting
    enum SlateStatus {
        Unstaked,
        Staked,
        Accepted
    }

    struct Slate {
        address recommender;
        bytes metadataHash;
        mapping(uint => bool) requestIncluded;
        uint[] requests;
        SlateStatus status;
        // Staking info
        address staker;
        uint stake;
        // Ballot info
        uint256 epochNumber;
        address resource;
    }

    // The slates created by the Gatekeeper.
    Slate[] public slates;

    // The number of tokens each account has available for voting
    mapping(address => uint) public voteTokenBalance;

    // The delegated account for each voting account
    mapping(address => address) public delegate;

    // The data committed when voting
    struct VoteCommitment {
        bytes32 commitHash;
        uint numTokens;
        bool committed;
        bool revealed;
    }

    // The votes for a slate in a contest
    struct SlateVotes {
        uint firstChoiceVotes;
        // slateID -> count
        mapping(uint => uint) secondChoiceVotes;
        uint totalSecondChoiceVotes;
    }

    enum ContestStatus {
        Empty,
        NoContest,
        Active,
        Finalized
    }

    struct Contest {
        ContestStatus status;

        // slateIDs
        uint[] slates;
        uint[] stakedSlates;
        uint256 lastStaked;

        // slateID -> tally
        mapping(uint => SlateVotes) votes;
        uint256 stakesDonated;

        // Intermediate results
        uint voteLeader;
        uint voteRunnerUp;
        uint256 leaderVotes;
        uint256 runnerUpVotes;
        uint256 totalVotes;

        // Final results
        uint winner;
    }

    // The current incumbent for a resource
    mapping(address => address) public incumbent;

    // A group of Contests in an epoch
    struct Ballot {
        // resource -> Contest
        mapping(address => Contest) contests;
        // NOTE: keep to avoid error about "internal or recursive type"
        bool created;

        // commitments for each voter
        mapping(address => VoteCommitment) commitments;
    }

    // All the ballots created so far
    // epoch number -> Ballot
    mapping(uint => Ballot) public ballots;


    // IMPLEMENTATION
    /**
     @dev Initialize a Gatekeeper contract.
     @param _startTime The start time of the first batch
     @param _parameters The parameter store to use
    */
    constructor(uint _startTime, ParameterStore _parameters, IERC20 _token) public {
        require(address(_parameters) != address(0), "Parameter store address cannot be zero");
        parameters = _parameters;

        require(address(_token) != address(0), "Token address cannot be zero");
        token = _token;

        startTime = _startTime;
    }

    // TIMING
    /**
    * @dev Get the number of the current epoch.
    */
    function currentEpochNumber() public view returns(uint) {
        uint elapsed = now.sub(startTime);
        uint epoch = elapsed.div(EPOCH_LENGTH);

        return epoch;
    }

    /**
    * @dev Get the start of the given epoch.
    */
    function epochStart(uint256 epoch) public view returns(uint) {
        return startTime.add(EPOCH_LENGTH.mul(epoch));
    }


    // SLATE GOVERNANCE
    /**
    * @dev Create a new slate with the associated requestIds and metadata hash.
    * @param resource The resource to submit the slate for
    * @param requestIDs A list of request IDs to include in the slate
    * @param metadataHash A reference to metadata about the slate
    */
    function recommendSlate(
        address resource,
        uint[] memory requestIDs,
        bytes memory metadataHash
    )
        public returns(uint)
    {
        require(isCurrentGatekeeper(), "Not current gatekeeper");
        require(slateSubmissionPeriodActive(resource), "Submission period not active");
        require(metadataHash.length > 0, "metadataHash cannot be empty");

        uint256 epochNumber = currentEpochNumber();

        // create slate
        Slate memory s = Slate({
            recommender: msg.sender,
            metadataHash: metadataHash,
            requests: requestIDs,
            status: SlateStatus.Unstaked,
            staker: address(0),
            stake: 0,
            epochNumber: epochNumber,
            resource: resource
        });

        // Record slate and return its ID
        uint slateID = slateCount();
        slates.push(s);

        // Set up the requests
        for (uint i = 0; i < requestIDs.length; i++) {
            uint requestID = requestIDs[i];
            require(requestID < requestCount(), "Invalid requestID");

            Request memory r = requests[requestID];
            // Every request's resource must match the one passed in
            require(r.resource == resource, "Resource does not match");

            // Requests must be current
            require(r.epochNumber == epochNumber, "Invalid epoch");

            // Requests cannot be duplicated
            require(slates[slateID].requestIncluded[requestID] == false, "Duplicate requests are not allowed");
            slates[slateID].requestIncluded[requestID] = true;
        }

        // Assign the slate to the appropriate contest
        ballots[epochNumber].contests[resource].slates.push(slateID);

        emit SlateCreated(slateID, msg.sender, requestIDs, metadataHash);
        return slateID;
    }

    /**
    @dev Get a list of the requests associated with a slate
    @param slateID The slate
     */
    function slateRequests(uint slateID) public view returns(uint[] memory) {
        return slates[slateID].requests;
    }

    /**
    @dev Stake tokens on the given slate to include it for consideration in votes. If the slate
    loses in a contest, the amount staked will go to the winner. If it wins, it will be returned.
    @param slateID The slate to stake on
     */
    function stakeTokens(uint slateID) public returns(bool) {
        require(isCurrentGatekeeper(), "Not current gatekeeper");
        require(slateID < slateCount(), "No slate exists with that slateID");
        require(slates[slateID].status == SlateStatus.Unstaked, "Slate has already been staked");

        address staker = msg.sender;

        // Staker must have enough tokens
        uint stakeAmount = parameters.getAsUint("slateStakeAmount");
        require(token.balanceOf(staker) >= stakeAmount, "Insufficient token balance");

        Slate storage slate = slates[slateID];

        // Submission period must be active
        require(slateSubmissionPeriodActive(slate.resource), "Submission period not active");
        uint256 epochNumber = currentEpochNumber();
        assert(slate.epochNumber == epochNumber);

        // Transfer tokens and update the slate's staking info
        // Must successfully transfer tokens from staker to this contract
        slate.staker = staker;
        slate.stake = stakeAmount;
        slate.status = SlateStatus.Staked;
        require(token.transferFrom(staker, address(this), stakeAmount), "Failed to transfer tokens");

        // Associate the slate with a contest and update the contest status
        // A vote can only happen if there is more than one associated slate
        Contest storage contest = ballots[slate.epochNumber].contests[slate.resource];
        contest.stakedSlates.push(slateID);
        // offset from the start of the epoch, for easier calculations
        contest.lastStaked = now.sub(epochStart(epochNumber));

        uint256 numSlates = contest.stakedSlates.length;
        if (numSlates == 1) {
            contest.status = ContestStatus.NoContest;
        } else {
            contest.status = ContestStatus.Active;
        }

        emit SlateStaked(slateID, staker, stakeAmount);
        return true;
    }


    /**
    @dev Withdraw tokens previously staked on a slate that was accepted through slate governance.
    @param slateID The slate to withdraw the stake from
     */
    function withdrawStake(uint slateID) public returns(bool) {
        require(slateID < slateCount(), "No slate exists with that slateID");

        // get slate
        Slate memory slate = slates[slateID];

        require(slate.status == SlateStatus.Accepted, "Slate has not been accepted");
        require(msg.sender == slate.staker, "Only the original staker can withdraw this stake");
        require(slate.stake > 0, "Stake has already been withdrawn");

        // Update slate and transfer tokens
        slates[slateID].stake = 0;
        require(token.transfer(slate.staker, slate.stake), "Failed to transfer tokens");

        emit StakeWithdrawn(slateID, slate.staker, slate.stake);
        return true;
    }

    /**
     @dev Deposit `numToken` tokens into the Gatekeeper to use in voting
     Assumes that `msg.sender` has approved the Gatekeeper to spend on their behalf
     @param numTokens The number of tokens to devote to voting
     */
    function depositVoteTokens(uint numTokens) public returns(bool) {
        require(isCurrentGatekeeper(), "Not current gatekeeper");
        address voter = msg.sender;

        // Voter must have enough tokens
        require(token.balanceOf(msg.sender) >= numTokens, "Insufficient token balance");

        // Transfer tokens to increase the voter's balance by `numTokens`
        uint originalBalance = voteTokenBalance[voter];
        voteTokenBalance[voter] = originalBalance.add(numTokens);

        // Must successfully transfer tokens from voter to this contract
        require(token.transferFrom(voter, address(this), numTokens), "Failed to transfer tokens");

        emit VotingTokensDeposited(voter, numTokens);
        return true;
    }

    /**
    @dev Withdraw `numTokens` vote tokens to the caller and decrease voting power
    @param numTokens The number of tokens to withdraw
     */
    function withdrawVoteTokens(uint numTokens) public returns(bool) {
        require(commitPeriodActive() == false, "Tokens locked during voting");

        address voter = msg.sender;

        uint votingRights = voteTokenBalance[voter];
        require(votingRights >= numTokens, "Insufficient vote token balance");

        // Transfer tokens to decrease the voter's balance by `numTokens`
        voteTokenBalance[voter] = votingRights.sub(numTokens);

        require(token.transfer(voter, numTokens), "Failed to transfer tokens");

        emit VotingTokensWithdrawn(voter, numTokens);
        return true;
    }


    /**
     @dev Set a delegate account that can vote on behalf of the voter
     @param _delegate The account being delegated to
     */
    function delegateVotingRights(address _delegate) public returns(bool) {
        address voter = msg.sender;
        require(voter != _delegate, "Delegate and voter cannot be equal");

        delegate[voter] = _delegate;

        emit VotingRightsDelegated(voter, _delegate);
        return true;
    }

    /**
     @dev Submit a commitment for the current ballot
     @param voter The voter to commit for
     @param commitHash The hash representing the voter's vote choices
     @param numTokens The number of vote tokens to use
     */
    function commitBallot(address voter, bytes32 commitHash, uint numTokens) public {
        uint epochNumber = currentEpochNumber();

        require(commitPeriodActive(), "Commit period not active");

        require(didCommit(epochNumber, voter) == false, "Voter has already committed for this ballot");
        require(commitHash != 0, "Cannot commit zero hash");

        address committer = msg.sender;

        // Must be a delegate if not the voter
        if (committer != voter) {
            require(committer == delegate[voter], "Not a delegate");
            require(voteTokenBalance[voter] >= numTokens, "Insufficient tokens");
        } else {
            // If the voter doesn't have enough tokens for voting, deposit more
            if (voteTokenBalance[voter] < numTokens) {
                uint remainder = numTokens.sub(voteTokenBalance[voter]);
                depositVoteTokens(remainder);
            }
        }

        assert(voteTokenBalance[voter] >= numTokens);

        // Set the voter's commitment for the current ballot
        Ballot storage ballot = ballots[epochNumber];
        VoteCommitment memory commitment = VoteCommitment({
            commitHash: commitHash,
            numTokens: numTokens,
            committed: true,
            revealed: false
        });

        ballot.commitments[voter] = commitment;

        emit BallotCommitted(epochNumber, committer, voter, numTokens, commitHash);
    }

    /**
     @dev Return true if the voter has committed for the given epoch
     @param epochNumber The epoch to check
     @param voter The voter's address
     */
    function didCommit(uint epochNumber, address voter) public view returns(bool) {
        return ballots[epochNumber].commitments[voter].committed;
    }

    /**
     @dev Get the commit hash for a given voter and epoch. Revert if voter has not committed yet.
     @param epochNumber The epoch to check
     @param voter The voter's address
     */
    function getCommitHash(uint epochNumber, address voter) public view returns(bytes32) {
        VoteCommitment memory v = ballots[epochNumber].commitments[voter];
        require(v.committed, "Voter has not committed for this ballot");

        return v.commitHash;
    }

    /**
     @dev Reveal a given voter's choices for the current ballot and record their choices
     @param voter The voter's address
     @param resources The contests to vote on
     @param firstChoices The corresponding first choices
     @param secondChoices The corresponding second choices
     @param salt The salt used to generate the original commitment
     */
    function revealBallot(
        uint256 epochNumber,
        address voter,
        address[] memory resources,
        uint[] memory firstChoices,
        uint[] memory secondChoices,
        uint salt
    ) public {
        uint256 epochTime = now.sub(epochStart(epochNumber));
        require(
            (REVEAL_PERIOD_START <= epochTime) && (epochTime < EPOCH_LENGTH),
            "Reveal period not active"
        );

        require(voter != address(0), "Voter address cannot be zero");
        require(resources.length == firstChoices.length, "All inputs must have the same length");
        require(firstChoices.length == secondChoices.length, "All inputs must have the same length");

        require(didCommit(epochNumber, voter), "Voter has not committed");
        require(didReveal(epochNumber, voter) == false, "Voter has already revealed");


        // calculate the hash
        bytes memory buf;
        uint votes = resources.length;
        for (uint i = 0; i < votes; i++) {
            buf = abi.encodePacked(
                buf,
                resources[i],
                firstChoices[i],
                secondChoices[i]
            );
        }
        buf = abi.encodePacked(buf, salt);
        bytes32 hashed = keccak256(buf);

        Ballot storage ballot = ballots[epochNumber];

        // compare to the stored data
        VoteCommitment memory v = ballot.commitments[voter];
        require(hashed == v.commitHash, "Submitted ballot does not match commitment");

        // Update tally for each contest
        for (uint i = 0; i < votes; i++) {
            address resource = resources[i];

            // get the contest for the current resource
            Contest storage contest = ballot.contests[resource];

            // Increment totals for first and second choice slates
            uint firstChoice = firstChoices[i];
            uint secondChoice = secondChoices[i];

            // Update first choice standings
            if (slates[firstChoice].status == SlateStatus.Staked) {
                SlateVotes storage firstChoiceSlate = contest.votes[firstChoice];
                contest.totalVotes = contest.totalVotes.add(v.numTokens);
                uint256 newCount = firstChoiceSlate.firstChoiceVotes.add(v.numTokens);

                // Update first choice standings
                if (firstChoice == contest.voteLeader) {
                    // Leader is still the leader
                    contest.leaderVotes = newCount;
                } else if (newCount > contest.leaderVotes) {
                    // This slate is now the leader, and the previous leader is now the runner-up
                    contest.voteRunnerUp = contest.voteLeader;
                    contest.runnerUpVotes = contest.leaderVotes;

                    contest.voteLeader = firstChoice;
                    contest.leaderVotes = newCount;
                } else if (newCount > contest.runnerUpVotes) {
                    // This slate overtook the previous runner-up
                    contest.voteRunnerUp = firstChoice;
                    contest.runnerUpVotes = newCount;
                }

                firstChoiceSlate.firstChoiceVotes = newCount;

                // Update second choice standings
                if (slates[secondChoice].status == SlateStatus.Staked) {
                    SlateVotes storage secondChoiceSlate = contest.votes[secondChoice];
                    secondChoiceSlate.totalSecondChoiceVotes = secondChoiceSlate.totalSecondChoiceVotes.add(v.numTokens);
                    firstChoiceSlate.secondChoiceVotes[secondChoice] = firstChoiceSlate.secondChoiceVotes[secondChoice].add(v.numTokens);
                }
            }
        }

        // update state
        ballot.commitments[voter].revealed = true;

        emit BallotRevealed(epochNumber, voter, v.numTokens);
    }

    /**
    @dev Reveal ballots for multiple voters
     */
    function revealManyBallots(
        uint256 epochNumber,
        address[] memory _voters,
        bytes[] memory _ballots,
        uint[] memory _salts
    ) public {
        uint numBallots = _voters.length;
        require(
            _salts.length == _voters.length && _ballots.length == _voters.length,
            "Inputs must have the same length"
        );

        for (uint i = 0; i < numBallots; i++) {
            // extract resources, firstChoices, secondChoices from the ballot
            (
                address[] memory resources,
                uint[] memory firstChoices,
                uint[] memory secondChoices
            ) = abi.decode(_ballots[i], (address[], uint[], uint[]));

            revealBallot(epochNumber, _voters[i], resources, firstChoices, secondChoices, _salts[i]);
        }
    }

    /**
     @dev Get the number of first-choice votes cast for the given slate and resource
     @param epochNumber The epoch
     @param resource The resource
     @param slateID The slate
     */
    function getFirstChoiceVotes(uint epochNumber, address resource, uint slateID) public view returns(uint) {
        SlateVotes storage v = ballots[epochNumber].contests[resource].votes[slateID];
        return v.firstChoiceVotes;
    }

    /**
     @dev Get the number of second-choice votes cast for the given slate and resource
     @param epochNumber The epoch
     @param resource The resource
     @param slateID The slate
     */
    function getSecondChoiceVotes(uint epochNumber, address resource, uint slateID) public view returns(uint) {
        // for each option that isn't this one, get the second choice votes
        Contest storage contest = ballots[epochNumber].contests[resource];
        uint numSlates = contest.stakedSlates.length;
        uint votes = 0;
        for (uint i = 0; i < numSlates; i++) {
            uint otherSlateID = contest.stakedSlates[i];
            if (otherSlateID != slateID) {
                SlateVotes storage v = contest.votes[otherSlateID];
                // get second-choice votes for the target slate
                votes = votes.add(v.secondChoiceVotes[slateID]);
            }
        }
        return votes;
    }

    /**
     @dev Return true if the voter has revealed for the given epoch
     @param epochNumber The epoch
     @param voter The voter's address
     */
    function didReveal(uint epochNumber, address voter) public view returns(bool) {
        return ballots[epochNumber].commitments[voter].revealed;
    }

    /**
     @dev Finalize contest, triggering a vote count if necessary, and update the status of the
     contest.

     If there is a single slate, it automatically wins. Otherwise, count votes.
     Count the first choice votes for each slate. If a slate has more than 50% of the votes,
     then it wins and the vote is finalized. Otherwise, wait for a runoff. If no
     votes are counted, finalize without a winner.

     @param epochNumber The epoch
     @param resource The resource to finalize for
     */
    function finalizeContest(uint epochNumber, address resource) public {
        require(isCurrentGatekeeper(), "Not current gatekeeper");

        // Finalization must be after the vote period (i.e when the given epoch is over)
        require(currentEpochNumber() > epochNumber, "Contest epoch still active");

        // Make sure the ballot has a contest for this resource
        Contest storage contest = ballots[epochNumber].contests[resource];
        require(contest.status == ContestStatus.Active || contest.status == ContestStatus.NoContest,
            "Either no contest is in progress for this resource, or it has been finalized");

        // A single staked slate in the contest automatically wins
        if (contest.status == ContestStatus.NoContest) {
            uint256 winningSlate = contest.stakedSlates[0];
            assert(slates[winningSlate].status == SlateStatus.Staked);

            contest.winner = winningSlate;
            contest.status = ContestStatus.Finalized;

            acceptSlate(winningSlate);
            emit ContestAutomaticallyFinalized(epochNumber, resource, winningSlate);
            return;
        }

        // no votes
        if (contest.totalVotes > 0) {
            uint256 winnerVotes = contest.leaderVotes;

            // If the winner has more than 50%, we are done
            // Otherwise, trigger a runoff
            if (winnerVotes.mul(2) > contest.totalVotes) {
                contest.winner = contest.voteLeader;
                acceptSlate(contest.winner);

                contest.status = ContestStatus.Finalized;
                emit VoteFinalized(epochNumber, resource, contest.winner, winnerVotes, contest.totalVotes);
            } else {
                emit VoteFailed(epochNumber, resource, contest.voteLeader, winnerVotes, contest.voteRunnerUp, contest.runnerUpVotes, contest.totalVotes);
                _finalizeRunoff(epochNumber, resource);
            }
        } else {
            // no one voted
            contest.status = ContestStatus.Finalized;
            emit ContestFinalizedWithoutWinner(epochNumber, resource);
            return;
        }
    }

    /**
     @dev Return the status of the specified contest
     */
    function contestStatus(uint epochNumber, address resource) public view returns(ContestStatus) {
        return ballots[epochNumber].contests[resource].status;
    }

    /**
     @dev Return the IDs of the slates (staked and unstaked) associated with the contest
     */
    function contestSlates(uint epochNumber, address resource) public view returns(uint[] memory) {
        return ballots[epochNumber].contests[resource].slates;
    }


    /**
     @dev Get the details of the specified contest
     */
    function contestDetails(uint256 epochNumber, address resource) external view
        returns(
            ContestStatus status,
            uint256[] memory allSlates,
            uint256[] memory stakedSlates,
            uint256 lastStaked,
            uint256 voteWinner,
            uint256 voteRunnerUp,
            uint256 winner
        ) {
        Contest memory c =  ballots[epochNumber].contests[resource];

        status = c.status;
        allSlates = c.slates;
        stakedSlates = c.stakedSlates;
        lastStaked = c.lastStaked;
        voteWinner = c.voteLeader;
        voteRunnerUp = c.voteRunnerUp;
        winner = c.winner;
    }

    /**
     @dev Trigger a runoff and update the status of the contest

     Revert if a runoff is not pending.
     Eliminate all slates but the top two from the initial vote. Re-count, including the
     second-choice votes for the top two slates. The slate with the most votes wins. In case
     of a tie, the earliest slate submitted (slate with the lowest ID) wins.

     @param epochNumber The epoch
     @param resource The resource to count votes for
     */
    function _finalizeRunoff(uint epochNumber, address resource) internal {
        require(isCurrentGatekeeper(), "Not current gatekeeper");

        Contest storage contest = ballots[epochNumber].contests[resource];

        uint voteLeader = contest.voteLeader;
        uint voteRunnerUp = contest.voteRunnerUp;

        // Get the number of second-choice votes for the top two choices, subtracting
        // any second choice votes where the first choice was for one of the top two
        SlateVotes storage leader = contest.votes[voteLeader];
        SlateVotes storage runnerUp = contest.votes[voteRunnerUp];

        uint256 secondChoiceVotesForLeader = leader.totalSecondChoiceVotes
            .sub(runnerUp.secondChoiceVotes[voteLeader]).sub(leader.secondChoiceVotes[voteLeader]);

        uint256 secondChoiceVotesForRunnerUp = runnerUp.totalSecondChoiceVotes
            .sub(leader.secondChoiceVotes[voteRunnerUp]).sub(runnerUp.secondChoiceVotes[voteRunnerUp]);

        uint256 leaderTotal = contest.leaderVotes.add(secondChoiceVotesForLeader);
        uint256 runnerUpTotal = contest.runnerUpVotes.add(secondChoiceVotesForRunnerUp);


        // Tally for the runoff
        uint runoffWinner = 0;
        uint runoffWinnerVotes = 0;
        uint runoffLoser = 0;
        uint runoffLoserVotes = 0;

        // Original winner has more votes, or it's tied and the original winner has a smaller ID
        if ((leaderTotal > runnerUpTotal) ||
           ((leaderTotal == runnerUpTotal) &&
            (voteLeader < voteRunnerUp)
            )) {
            runoffWinner = voteLeader;
            runoffWinnerVotes = leaderTotal;
            runoffLoser = voteRunnerUp;
            runoffLoserVotes = runnerUpTotal;
        } else {
            runoffWinner = voteRunnerUp;
            runoffWinnerVotes = runnerUpTotal;
            runoffLoser = voteLeader;
            runoffLoserVotes = leaderTotal;
        }

        // Update state
        contest.winner = runoffWinner;
        contest.status = ContestStatus.Finalized;
        acceptSlate(runoffWinner);

        emit RunoffFinalized(epochNumber, resource, runoffWinner, runoffWinnerVotes, runoffLoser, runoffLoserVotes);
    }


    /**
     @dev Send tokens of the rejected slates to the token capacitor.
     @param epochNumber The epoch
     @param resource The resource
     */
    function donateChallengerStakes(uint256 epochNumber, address resource, uint256 startIndex, uint256 count) public {
        Contest storage contest = ballots[epochNumber].contests[resource];
        require(contest.status == ContestStatus.Finalized, "Contest is not finalized");

        uint256 numSlates = contest.stakedSlates.length;
        require(contest.stakesDonated != numSlates, "All stakes donated");

        // If there are still stakes to be donated, continue
        require(startIndex == contest.stakesDonated, "Invalid start index");

        uint256 endIndex = startIndex.add(count);
        require(endIndex <= numSlates, "Invalid end index");

        address stakeDonationAddress = parameters.getAsAddress("stakeDonationAddress");
        IDonationReceiver donationReceiver = IDonationReceiver(stakeDonationAddress);
        bytes memory stakeDonationHash = "Qmepxeh4KVkyHYgt3vTjmodB5RKZgUEmdohBZ37oKXCUCm";

        for (uint256 i = startIndex; i < endIndex; i++) {
            uint256 slateID = contest.stakedSlates[i];
            Slate storage slate = slates[slateID];
            if (slate.status != SlateStatus.Accepted) {
                uint256 donationAmount = slate.stake;
                slate.stake = 0;

                // Only donate for non-zero amounts
                if (donationAmount > 0) {
                    require(
                        token.approve(address(donationReceiver), donationAmount),
                        "Failed to approve Gatekeeper to spend tokens"
                    );
                    donationReceiver.donate(address(this), donationAmount, stakeDonationHash);
                }
            }
        }

        // Update state
        contest.stakesDonated = endIndex;
    }

    /**
     @dev Return the ID of the winning slate for the given epoch and resource
     Revert if the vote has not been finalized yet.
     @param epochNumber The epoch
     @param resource The resource of interest
     */
    function getWinningSlate(uint epochNumber, address resource) public view returns(uint) {
        Contest storage c = ballots[epochNumber].contests[resource];
        require(c.status == ContestStatus.Finalized, "Vote is not finalized yet");

        return c.winner;
    }


    // ACCESS CONTROL
    /**
    @dev Request permission to perform the action described in the metadataHash
    @param metadataHash A reference to metadata about the action
    */
    function requestPermission(bytes memory metadataHash) public returns(uint) {
        require(isCurrentGatekeeper(), "Not current gatekeeper");
        require(metadataHash.length > 0, "metadataHash cannot be empty");
        address resource = msg.sender;
        uint256 epochNumber = currentEpochNumber();

        require(slateSubmissionPeriodActive(resource), "Submission period not active");

        // If the request is created in epoch n, expire at the start of epoch n + 2
        uint256 expirationTime = epochStart(epochNumber.add(2));

        // Create new request
        Request memory r = Request({
            metadataHash: metadataHash,
            resource: resource,
            approved: false,
            expirationTime: expirationTime,
            epochNumber: epochNumber
        });

        // Record request and return its ID
        uint requestID = requestCount();
        requests.push(r);

        emit PermissionRequested(epochNumber, resource, requestID, metadataHash);
        return requestID;
    }

    /**
    @dev Update a slate and its associated requests
    @param slateID The slate to update
     */
    function acceptSlate(uint slateID) private {
        // Mark the slate as accepted
        Slate storage s = slates[slateID];
        s.status = SlateStatus.Accepted;

        // Record the incumbent
        if (incumbent[s.resource] != s.recommender) {
            incumbent[s.resource] = s.recommender;
        }

        // mark all of its requests as approved
        uint[] memory requestIDs = s.requests;
        for (uint i = 0; i < requestIDs.length; i++) {
            uint requestID = requestIDs[i];
            requests[requestID].approved = true;
        }
    }

    /**
    @dev Return true if the requestID has been approved via slate governance and has not expired
    @param requestID The ID of the request to check
     */
    function hasPermission(uint requestID) public view returns(bool) {
        return requests[requestID].approved && now < requests[requestID].expirationTime;
    }


    // MISCELLANEOUS GETTERS
    function slateCount() public view returns(uint256) {
        return slates.length;
    }

    function requestCount() public view returns (uint256) {
        return requests.length;
    }

    /**
    @dev Return the slate submission deadline for the given resource
    @param epochNumber The epoch
    @param resource The resource
     */
    function slateSubmissionDeadline(uint256 epochNumber, address resource) public view returns(uint256) {
        Contest memory contest = ballots[epochNumber].contests[resource];
        uint256 offset = (contest.lastStaked.add(COMMIT_PERIOD_START)).div(2);

        return epochStart(epochNumber).add(offset);
    }

    /**
    @dev Return true if the slate submission period is active for the given resource and the
     current epoch.
     */
    function slateSubmissionPeriodActive(address resource) public view returns(bool) {
        uint256 epochNumber = currentEpochNumber();
        uint256 start = epochStart(epochNumber).add(SLATE_SUBMISSION_PERIOD_START);
        uint256 end = slateSubmissionDeadline(epochNumber, resource);

        return (start <= now) && (now < end);
    }

    /**
    @dev Return true if the commit period is active for the current epoch
     */
    function commitPeriodActive() private view returns(bool) {
        uint256 epochTime = now.sub(epochStart(currentEpochNumber()));
        return (COMMIT_PERIOD_START <= epochTime) && (epochTime < REVEAL_PERIOD_START);
    }

    /**
    @dev Return true if this is the Gatekeeper currently pointed to by the ParameterStore
     */
    function isCurrentGatekeeper() public view returns(bool) {
        return parameters.getAsAddress("gatekeeperAddress") == address(this);
    }
}