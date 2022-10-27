/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/common/IForwarder.sol";

import "@aragon/os/contracts/lib/math/SafeMath.sol";
import "@aragon/os/contracts/lib/math/SafeMath64.sol";

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";

contract Voting is IForwarder, AragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    uint128 private constant MAX_UINT_128 = 2 ** 128 - 1;
    uint128 private constant MAX_UINT_64 = 2 ** 64 - 1;

    bytes32 public constant CREATE_VOTES_ROLE = 0xe7dcd7275292e064d090fbc5f3bd7995be23b502c1fed5cd94cfddbbdcd32bbc; //keccak256("CREATE_VOTES_ROLE");
    bytes32 public constant MODIFY_SUPPORT_ROLE = 0xda3972983e62bdf826c4b807c4c9c2b8a941e1f83dfa76d53d6aeac11e1be650; //keccak256("MODIFY_SUPPORT_ROLE");
    bytes32 public constant MODIFY_QUORUM_ROLE = 0xad15e7261800b4bb73f1b69d3864565ffb1fd00cb93cf14fe48da8f1f2149f39; //keccak256("MODIFY_QUORUM_ROLE");

    bytes32 public constant SET_MIN_BALANCE_ROLE = 0xb1f3f26f63ad27cd630737a426f990492f5c674208299d6fb23bb2b0733d3d66; //keccak256("SET_MIN_BALANCE_ROLE")
    bytes32 public constant SET_MIN_TIME_ROLE = 0xe7ab0252519cd959720b328191bed7fe61b8e25f77613877be7070646d12daf0; //keccak256("SET_MIN_TIME_ROLE")

    bytes32 public constant ENABLE_VOTE_CREATION = 0xecb50dc3e77ba8a59697a3cc090a29b4cbd3c1f2b6b3aea524e0d166969592b9; //keccak256("ENABLE_VOTE_CREATION")

    bytes32 public constant DISABLE_VOTE_CREATION = 0x40b01f8b31b51596de2eeab8c325ff77cc3695c1c1875d66ff31176e7148d2a1; //keccack256("DISABLE_VOTE_CREATION")

    uint64 public constant PCT_BASE = 10 ** 18; // 0% = 0; 1% = 10^16; 100% = 10^18

    string private constant ERROR_NO_VOTE = "VOTING_NO_VOTE";
    string private constant ERROR_INIT_PCTS = "VOTING_INIT_PCTS";
    string private constant ERROR_CHANGE_SUPPORT_PCTS = "VOTING_CHANGE_SUPPORT_PCTS";
    string private constant ERROR_CHANGE_QUORUM_PCTS = "VOTING_CHANGE_QUORUM_PCTS";
    string private constant ERROR_INIT_SUPPORT_TOO_BIG = "VOTING_INIT_SUPPORT_TOO_BIG";
    string private constant ERROR_CHANGE_SUPPORT_TOO_BIG = "VOTING_CHANGE_SUPP_TOO_BIG";
    string private constant ERROR_CAN_NOT_VOTE = "VOTING_CAN_NOT_VOTE";
    string private constant ERROR_MALFORMED_CONTINUOUS_VOTE = "MALFORMED_CONTINUOUS_VOTE";
    string private constant ERROR_CAN_NOT_EXECUTE = "VOTING_CAN_NOT_EXECUTE";
    string private constant ERROR_CAN_NOT_FORWARD = "VOTING_CAN_NOT_FORWARD";
    string private constant ERROR_NO_VOTING_POWER = "VOTING_NO_VOTING_POWER";

    enum VoterState { Absent, Yea, Nay, Even }

    struct Vote {
        bool executed;
        uint64 startDate;
        uint64 snapshotBlock;
        uint64 supportRequiredPct;
        uint64 minAcceptQuorumPct;
        uint256 yea;
        uint256 nay;
        uint256 votingPower;
        bytes executionScript;
        mapping (address => VoterState) voters;
    }

    MiniMeToken public token;
    uint64 public supportRequiredPct;
    uint64 public minAcceptQuorumPct;
    uint64 public voteTime;

    //2500000000000000000000
    uint256 public minBalanceLowerLimit;
    uint256 public minBalanceUpperLimit;
    //43200
    uint256 public minTimeLowerLimit;
    //1209600
    uint256 public minTimeUpperLimit;

    uint256 public minBalance;
    uint256 public minTime;

    bool public enableVoteCreation;

    // We are mimicing an array, we use a mapping instead to make app upgrade more graceful
    mapping (uint256 => Vote) internal votes;
    uint256 public votesLength;

    mapping(address => uint256) public lastCreateVoteTimes;

    event StartVote(uint256 indexed voteId, address indexed creator, string metadata, uint256 minBalance, uint256 minTime, uint256 totalSupply, uint256 creatorVotingPower);
    event CastVote(uint256 indexed voteId, address indexed voter, bool supports, uint256 stake);
    event ExecuteVote(uint256 indexed voteId);
    event ChangeSupportRequired(uint64 supportRequiredPct);
    event ChangeMinQuorum(uint64 minAcceptQuorumPct);

    event MinimumBalanceSet(uint256 minBalance);
    event MinimumTimeSet(uint256 minTime);

    modifier voteExists(uint256 _voteId) {
        require(_voteId < votesLength, ERROR_NO_VOTE);
        _;
    }

    modifier minBalanceCheck(uint256 _minBalance) {
        //_minBalance to be at least the equivalent of 10k locked for a year (1e18 precision)
        require(_minBalance >= minBalanceLowerLimit && _minBalance <= minBalanceUpperLimit, "Min balance should be within initialization hardcoded limits");
        _;
    }

    modifier minTimeCheck(uint256 _minTime) {
        require(_minTime >= minTimeLowerLimit && _minTime <= minTimeUpperLimit, "Min time should be within initialization hardcoded limits");
        _;
    }

    /**
    * @notice Initialize Voting app with `_token.symbol(): string` for governance, minimum support of `@formatPct(_supportRequiredPct)`%, minimum acceptance quorum of `@formatPct(_minAcceptQuorumPct)`%, and a voting duration of `@transformTime(_voteTime)`
    * @param _token MiniMeToken Address that will be used as governance token
    * @param _supportRequiredPct Percentage of yeas in casted votes for a vote to succeed (expressed as a percentage of 10^18; eg. 10^16 = 1%, 10^18 = 100%)
    * @param _minAcceptQuorumPct Percentage of yeas in total possible votes for a vote to succeed (expressed as a percentage of 10^18; eg. 10^16 = 1%, 10^18 = 100%)
    * @param _voteTime Seconds that a vote will be open for token holders to vote (unless enough yeas or nays have been cast to make an early decision)
    * @param _minBalance Minumum balance that a token holder should have to create a new vote
    * @param _minTime Minimum time between a user's previous vote and creating a new vote
    * @param _minBalanceLowerLimit Hardcoded lower limit for _minBalance on initialization
    * @param _minTimeLowerLimit Hardcoded lower limit for _minTime on initialization
    * @param _minTimeUpperLimit Hardcoded upper limit for _minTime on initialization
    */
    function initialize(MiniMeToken _token, 
        uint64 _supportRequiredPct, 
        uint64 _minAcceptQuorumPct, 
        uint64 _voteTime,
        uint256 _minBalance,
        uint256 _minTime,
        uint256 _minBalanceLowerLimit,
        uint256 _minBalanceUpperLimit,
        uint256 _minTimeLowerLimit,
        uint256 _minTimeUpperLimit
    ) external onlyInit {
        assert(CREATE_VOTES_ROLE == keccak256("CREATE_VOTES_ROLE"));
        assert(MODIFY_SUPPORT_ROLE == keccak256("MODIFY_SUPPORT_ROLE"));
        assert(MODIFY_QUORUM_ROLE == keccak256("MODIFY_QUORUM_ROLE"));
        assert(SET_MIN_BALANCE_ROLE == keccak256("SET_MIN_BALANCE_ROLE"));
        assert(SET_MIN_TIME_ROLE == keccak256("SET_MIN_TIME_ROLE"));
        assert(DISABLE_VOTE_CREATION == keccak256("DISABLE_VOTE_CREATION"));
        assert(ENABLE_VOTE_CREATION == keccak256("ENABLE_VOTE_CREATION"));

        initialized();

        require(_minAcceptQuorumPct <= _supportRequiredPct, ERROR_INIT_PCTS);
        require(_supportRequiredPct < PCT_BASE, ERROR_INIT_SUPPORT_TOO_BIG);

        require(_minBalance >= _minBalanceLowerLimit && _minBalance <= _minBalanceUpperLimit);
        require(_minTime >= _minTimeLowerLimit && _minTime <= _minTimeUpperLimit);

        token = _token;
        supportRequiredPct = _supportRequiredPct;
        minAcceptQuorumPct = _minAcceptQuorumPct;
        voteTime = _voteTime;

        uint256 decimalsMul = uint256(10) ** token.decimals();

        minBalance = _minBalance.mul(decimalsMul);
        minTime = _minTime;

        minBalanceLowerLimit = _minBalanceLowerLimit.mul(decimalsMul);
        minBalanceUpperLimit = _minBalanceUpperLimit.mul(decimalsMul);
        minTimeLowerLimit = _minTimeLowerLimit;
        minTimeUpperLimit = _minTimeUpperLimit;

        emit MinimumBalanceSet(minBalance);
        emit MinimumTimeSet(minTime);

        enableVoteCreation = true;
    }

    /**
    * @notice Change required support to `@formatPct(_supportRequiredPct)`%
    * @param _supportRequiredPct New required support
    */
    function changeSupportRequiredPct(uint64 _supportRequiredPct)
        external
        authP(MODIFY_SUPPORT_ROLE, arr(uint256(_supportRequiredPct), uint256(supportRequiredPct)))
    {
        require(minAcceptQuorumPct <= _supportRequiredPct, ERROR_CHANGE_SUPPORT_PCTS);
        require(_supportRequiredPct < PCT_BASE, ERROR_CHANGE_SUPPORT_TOO_BIG);
        supportRequiredPct = _supportRequiredPct;

        emit ChangeSupportRequired(_supportRequiredPct);
    }

    /**
    * @notice Change minimum acceptance quorum to `@formatPct(_minAcceptQuorumPct)`%
    * @param _minAcceptQuorumPct New acceptance quorum
    */
    function changeMinAcceptQuorumPct(uint64 _minAcceptQuorumPct)
        external
        authP(MODIFY_QUORUM_ROLE, arr(uint256(_minAcceptQuorumPct), uint256(minAcceptQuorumPct)))
    {
        require(_minAcceptQuorumPct <= supportRequiredPct, ERROR_CHANGE_QUORUM_PCTS);
        minAcceptQuorumPct = _minAcceptQuorumPct;

        emit ChangeMinQuorum(_minAcceptQuorumPct);
    }

    /**
    * @notice Change minimum balance needed to create a vote to `_minBalance`
    * @param _minBalance New minimum balance
    */

    function setMinBalance(uint256 _minBalance) external auth(SET_MIN_BALANCE_ROLE) minBalanceCheck(_minBalance) {
        //min balance can't be set to lower than 10k * 1 year
        minBalance = _minBalance;

        emit MinimumBalanceSet(_minBalance);
    }

    /**
    * @notice Change minimum time needed to pass between user's previous vote and a user creating a new vote
    * @param _minTime New minumum time
    */

    function setMinTime(uint256 _minTime) external auth(SET_MIN_TIME_ROLE) minTimeCheck(_minTime) {
        //min time should be within initialized hardcoded limits
        minTime = _minTime;

        emit MinimumTimeSet(_minTime);
    }

    //later role will be set to 0x0 - noone
    function disableVoteCreationOnce() external auth(DISABLE_VOTE_CREATION) {
        enableVoteCreation = false;
    }

    function enableVoteCreationOnce() external auth(ENABLE_VOTE_CREATION) {
        enableVoteCreation = true;
    }

    /**
    * @notice Create a new vote about "`_metadata`"
    * @param _executionScript EVM script to be executed on approval
    * @param _metadata Vote metadata
    * @return voteId Id for newly created vote
    */
    function newVote(bytes _executionScript, string _metadata) external auth(CREATE_VOTES_ROLE) returns (uint256 voteId) {
        return _newVote(_executionScript, _metadata, true, true);
    }

    /**
    * @notice Create a new vote about "`_metadata`"
    * @param _executionScript EVM script to be executed on approval
    * @param _metadata Vote metadata
    * @param _castVote Whether to also cast newly created vote
    * @param _executesIfDecided Whether to also immediately execute newly created vote if decided
    * @return voteId id for newly created vote
    */
    function newVote(bytes _executionScript, string _metadata, bool _castVote, bool _executesIfDecided)
        external
        auth(CREATE_VOTES_ROLE)
        returns (uint256 voteId)
    {
        return _newVote(_executionScript, _metadata, _castVote, _executesIfDecided);
    }

    /**
    * @notice Vote a percentage value in favor of a vote
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    * @param _voteData Packed vote data containing both voteId and the vote in favor percentage (where 0 is no, and 1e18 is yes)
    *          Vote data packing
    * |  yeaPct  |  nayPct  |   voteId  |
    * |  64b     |  64b     |   128b    |
    * @param _supports Whether voter supports the vote (preserved for backward compatibility purposes)
    * @param _executesIfDecided Whether the vote should execute its action if it becomes decided
    */
    function vote(uint256 _voteData, bool _supports, bool _executesIfDecided) external voteExists(_decodeData(_voteData, 0, MAX_UINT_128)) {
        uint256 voteId = _decodeData(_voteData, 0, MAX_UINT_128);
        uint256 nayPct = _decodeData(_voteData, 128, MAX_UINT_64);
        uint256 yeaPct = _decodeData(_voteData, 192, MAX_UINT_64);

        require(_canVote(voteId, msg.sender), ERROR_CAN_NOT_VOTE);

        if (yeaPct == 0 && nayPct == 0) {
            // Keep backwards compatibility
            if (_supports) {
                yeaPct = PCT_BASE;
            } else {
                nayPct = PCT_BASE;
            }
        } else {
            require(!_supports && yeaPct.add(nayPct) <= PCT_BASE, ERROR_MALFORMED_CONTINUOUS_VOTE);
        }
        _vote(voteId, yeaPct, nayPct, msg.sender, _executesIfDecided);
    }

    /**
    * @notice Vote `@formatPct(_yeaPct)`% in favor and `@formatPct(_nayPct)`% against of vote #`_voteId`
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    * @param _voteId Id for vote
    * @param _yeaPct Percentage of support, where 0 is no support, and 1e18 is total support
    * @param _nayPct Percentage of opposition, where 0 is no oposition, and 1e18 is total oposition
    * @param _executesIfDecided Whether the vote should execute its action if it becomes decided
    */
    function votePct(uint256 _voteId, uint256 _yeaPct, uint256 _nayPct, bool _executesIfDecided) external voteExists(_voteId) {
        require(_canVote(_voteId, msg.sender), ERROR_CAN_NOT_VOTE);
        require(_yeaPct.add(_nayPct) <= PCT_BASE, ERROR_MALFORMED_CONTINUOUS_VOTE);
        _vote(_voteId, _yeaPct, _nayPct, msg.sender, _executesIfDecided);
    }

    /**
    * @notice Execute vote #`_voteId`
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    * @param _voteId Id for vote
    */
    function executeVote(uint256 _voteId) external voteExists(_voteId) {
        _executeVote(_voteId);
    }

    // Forwarding fns

    /**
    * @notice Tells whether the Voting app is a forwarder or not
    * @dev IForwarder interface conformance
    * @return Always true
    */
    function isForwarder() external pure returns (bool) {
        return true;
    }

    /**
    * @notice Creates a vote to execute the desired action, and casts a support vote if possible
    * @dev IForwarder interface conformance
    * @param _evmScript Start vote with script
    */
    function forward(bytes _evmScript) public {
        require(canForward(msg.sender, _evmScript), ERROR_CAN_NOT_FORWARD);
        _newVote(_evmScript, "", true, true);
    }

    /**
    * @notice Tells whether `_sender` can forward actions or not
    * @dev IForwarder interface conformance
    * @param _sender Address of the account intending to forward an action
    * @return True if the given address can create votes, false otherwise
    */
    function canForward(address _sender, bytes) public view returns (bool) {
        // Note that `canPerform()` implicitly does an initialization check itself
        return canPerform(_sender, CREATE_VOTES_ROLE, arr()) && canCreateNewVote(_sender);
    }

    // Getter fns

    /**
    * @notice Tells whether a vote #`_voteId` can be executed or not
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    * @return True if the given vote can be executed, false otherwise
    */
    function canExecute(uint256 _voteId) public view voteExists(_voteId) returns (bool) {
        return _canExecute(_voteId);
    }

    /**
    * @notice Tells whether `_sender` can participate in the vote #`_voteId` or not
    * @dev Initialization check is implicitly provided by `voteExists()` as new votes can only be
    *      created via `newVote(),` which requires initialization
    * @return True if the given voter can participate a certain vote, false otherwise
    */
    function canVote(uint256 _voteId, address _voter) public view voteExists(_voteId) returns (bool) {
        return _canVote(_voteId, _voter);
    }

    function canCreateNewVote(address _sender) public view returns(bool) {
        return enableVoteCreation && token.balanceOf(_sender) >= minBalance &&  block.timestamp.sub(minTime) >= lastCreateVoteTimes[_sender];
    }

    /**
    * @dev Return all information for a vote by its ID
    * @param _voteId Vote identifier
    * @return Vote open status
    * @return Vote executed status
    * @return Vote start date
    * @return Vote snapshot block
    * @return Vote support required
    * @return Vote minimum acceptance quorum
    * @return Vote yeas amount
    * @return Vote nays amount
    * @return Vote power
    * @return Vote script
    */
    function getVote(uint256 _voteId)
        public
        view
        voteExists(_voteId)
        returns (
            bool open,
            bool executed,
            uint64 startDate,
            uint64 snapshotBlock,
            uint64 supportRequired,
            uint64 minAcceptQuorum,
            uint256 yea,
            uint256 nay,
            uint256 votingPower,
            bytes script
        )
    {
        Vote storage vote_ = votes[_voteId];

        open = _isVoteOpen(vote_);
        executed = vote_.executed;
        startDate = vote_.startDate;
        snapshotBlock = vote_.snapshotBlock;
        supportRequired = vote_.supportRequiredPct;
        minAcceptQuorum = vote_.minAcceptQuorumPct;
        yea = vote_.yea;
        nay = vote_.nay;
        votingPower = vote_.votingPower;
        script = vote_.executionScript;
    }

    /**
    * @dev Return the state of a voter for a given vote by its ID
    * @param _voteId Vote identifier
    * @return VoterState of the requested voter for a certain vote
    */
    function getVoterState(uint256 _voteId, address _voter) public view voteExists(_voteId) returns (VoterState) {
        return votes[_voteId].voters[_voter];
    }

    // Internal fns

    /**
    * @dev Internal function to create a new vote
    * @return voteId id for newly created vote
    */
    function _newVote(bytes _executionScript, string _metadata, bool _castVote, bool _executesIfDecided) internal returns (uint256 voteId) {
        require(canCreateNewVote(msg.sender));
        uint64 snapshotBlock = getBlockNumber64() - 1; // avoid double voting in this very block
        uint256 votingPower = token.totalSupplyAt(snapshotBlock);
        require(votingPower > 0, ERROR_NO_VOTING_POWER);

        voteId = votesLength++;

        Vote storage vote_ = votes[voteId];
        vote_.startDate = getTimestamp64();
        vote_.snapshotBlock = snapshotBlock;
        vote_.supportRequiredPct = supportRequiredPct;
        vote_.minAcceptQuorumPct = minAcceptQuorumPct;
        vote_.votingPower = votingPower;
        vote_.executionScript = _executionScript;

        emit StartVote(voteId, msg.sender, _metadata, minBalance, minTime, token.totalSupply(), token.balanceOfAt(msg.sender, snapshotBlock));

        lastCreateVoteTimes[msg.sender] = getTimestamp64();

        if (_castVote && _canVote(voteId, msg.sender)) {
            _vote(voteId, PCT_BASE, 0, msg.sender, _executesIfDecided);
        }
    }

    /**
    * @dev Internal function to cast a vote. It assumes the queried vote exists.
    */
    function _vote(uint256 _voteId, uint256 _yeaPct, uint256 _nayPct, address _voter, bool _executesIfDecided) internal {
        Vote storage vote_ = votes[_voteId];

        VoterState state = vote_.voters[_voter];
        require(state == VoterState.Absent, "Can't change votes");
        // This could re-enter, though we can assume the governance token is not malicious
        uint256 balance = token.balanceOfAt(_voter, vote_.snapshotBlock);
        uint256 voterStake = uint256(2).mul(balance).mul(vote_.startDate.add(voteTime).sub(getTimestamp64())).div(voteTime);
        if(voterStake > balance) {
            voterStake = balance;
        }

        uint256 yea = voterStake.mul(_yeaPct).div(PCT_BASE);
        uint256 nay = voterStake.mul(_nayPct).div(PCT_BASE);

        if (yea > 0) {
            vote_.yea = vote_.yea.add(yea);
        }
        if (nay > 0) {
            vote_.nay = vote_.nay.add(nay);
        }

        vote_.voters[_voter] = yea == nay ? VoterState.Even : yea > nay ? VoterState.Yea : VoterState.Nay;

        if (yea > 0) {
          emit CastVote(_voteId, _voter, true, yea);
        }
        if (nay > 0) {
          emit CastVote(_voteId, _voter, false, nay);
        }

        if (_executesIfDecided && _canExecute(_voteId)) {
            // We've already checked if the vote can be executed with `_canExecute()`
            _unsafeExecuteVote(_voteId);
        }
    }

    /**
    * @dev Internal function to execute a vote. It assumes the queried vote exists.
    */
    function _executeVote(uint256 _voteId) internal {
        require(_canExecute(_voteId), ERROR_CAN_NOT_EXECUTE);
        _unsafeExecuteVote(_voteId);
    }

    /**
    * @dev Unsafe version of _executeVote that assumes you have already checked if the vote can be executed and exists
    */
    function _unsafeExecuteVote(uint256 _voteId) internal {
        Vote storage vote_ = votes[_voteId];

        vote_.executed = true;

        bytes memory input = new bytes(0); // TODO: Consider input for voting scripts
        runScript(vote_.executionScript, input, new address[](0));

        emit ExecuteVote(_voteId);
    }

    /**
    * @dev Internal function to check if a vote can be executed. It assumes the queried vote exists.
    * @return True if the given vote can be executed, false otherwise
    */
    function _canExecute(uint256 _voteId) internal view returns (bool) {
        Vote storage vote_ = votes[_voteId];

        if(_isVoteOpen(vote_)) {
            return false;
        }

        if (vote_.executed) {
            return false;
        }

        // Voting is already decided
        if (_isValuePct(vote_.yea, vote_.votingPower, vote_.supportRequiredPct)) {
            return true;
        }

        // Vote ended?
        if (_isVoteOpen(vote_)) {
            return false;
        }
        // Has enough support?
        uint256 totalVotes = vote_.yea.add(vote_.nay);
        if (!_isValuePct(vote_.yea, totalVotes, vote_.supportRequiredPct)) {
            return false;
        }
        // Has min quorum?
        if (!_isValuePct(totalVotes, vote_.votingPower, vote_.minAcceptQuorumPct)) {
            return false;
        }

        return true;
    }

    /**
    * @dev Internal function to check if a voter can participate on a vote. It assumes the queried vote exists.
    * @return True if the given voter can participate a certain vote, false otherwise
    */
    function _canVote(uint256 _voteId, address _voter) internal view returns (bool) {
        Vote storage vote_ = votes[_voteId];
        return _isVoteOpen(vote_) && token.balanceOfAt(_voter, vote_.snapshotBlock) > 0;
    }

    /**
    * @dev Internal function to check if a vote is still open
    * @return True if the given vote is open, false otherwise
    */
    function _isVoteOpen(Vote storage vote_) internal view returns (bool) {
        return getTimestamp64() < vote_.startDate.add(voteTime) && !vote_.executed;
    }

    /**
    * @dev Calculates whether `_value` is more than a percentage `_pct` of `_total`
    */
    function _isValuePct(uint256 _value, uint256 _total, uint256 _pct) internal pure returns (bool) {
        if (_total == 0) {
            return false;
        }

        uint256 computedPct = _value.mul(PCT_BASE) / _total;
        return computedPct > _pct;
    }

    /**
    * @dev Decodes data by performing bitwise operations.
    * @param _value Value containing the data
    * @param _shiftValue Number of bits to shift to the right
    * @param _maskValue Number of bits to apply as a mask to the value
     */
    function _decodeData(uint256 _value, uint256 _shiftValue, uint256 _maskValue) internal pure returns(uint256) {
        return uint256((_value >> _shiftValue) & _maskValue);
    }
}