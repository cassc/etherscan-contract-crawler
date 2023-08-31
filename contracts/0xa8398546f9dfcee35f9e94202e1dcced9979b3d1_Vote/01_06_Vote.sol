// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../interfaces/tokenomics/ITORUSLockerV2.sol";

contract Vote is Ownable, ReentrancyGuard {
    address public voteLocker;

    uint256 internal constant DURATION = 7 days;
    uint256 public constant MAX_VOTE_DELAY = 7 days;
    uint256 internal constant WEEK = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint256 public active_period;
    uint256 public VOTE_DELAY; // delay between votes in seconds

    mapping(address => mapping(address => uint256)) public votes; // user => pool => votes
    mapping(address => address[]) public poolVote; // user => pool
    mapping(uint256 => mapping(address => uint256)) internal weightsPerEpoch; // timestamp => pool => weights
    mapping(uint256 => uint256) internal totalWeightsPerEpoch; // timestamp => total weights
    mapping(address => uint256) public lastVoted; // user => timestamp of last vote
    mapping(address => bool) public isAlive; // crv pool => boolean [is pool alive for vote?]
    mapping(address => bool) public poolAdded; // crv pool => existance
    address[] internal pools;

    event Voted(address indexed voter, uint256 weight);

    constructor(address _voteLocker) public {
        voteLocker = _voteLocker;
    }

    // @notice Vote for pools
    // @param _poolVote array of LP addresses to vote
    // @param _weights  array of weights for each LPs
    function vote(address[] calldata _poolVote, uint256[] calldata _weights) external nonReentrant {
        _voteDelay(msg.sender);
        _vote(msg.sender, _poolVote, _weights);
        lastVoted[msg.sender] = _epochTimestamp() + 1;
    }

    function _vote(address _user, address[] memory _poolVote, uint256[] memory _weights) internal {
        _reset(_user);
        uint256 _poolCnt = _poolVote.length;
        uint256 _weight = ITORUSLockerV2(voteLocker).balanceOf(_user);
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;
        uint256 _usedWeight = 0;
        uint256 _time = _epochTimestamp();
        active_period = _time;
        
        for (uint256 i = 0; i < _poolCnt; i++) {
            if (isAlive[_poolVote[i]]) _totalVoteWeight += _weights[i];
        }

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];

            if (isAlive[_pool]) {
                uint256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;

                require(votes[_user][_pool] == 0);
                require(_poolWeight != 0);

                poolVote[_user].push(_pool);
                weightsPerEpoch[_time][_pool] += _poolWeight;

                votes[_user][_pool] += _poolWeight;

                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(msg.sender, _poolWeight);
            }
        }
        totalWeightsPerEpoch[_time] += _totalWeight;
    }

    function _reset(address _user) internal {
        address[] storage _poolVote = poolVote[_user];
        uint256 _poolVoteCnt = _poolVote.length;
        uint256 _totalWeight = 0;
        uint256 _time = _epochTimestamp();

        for (uint256 i; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[_user][_pool];

            if (_votes != 0) {
                if (lastVoted[_user] > _time) {
                    weightsPerEpoch[_time][_pool] -= _votes;
                }
                votes[_user][_pool] = 0;

                if (isAlive[_pool]) {
                    _totalWeight += _votes;
                }
            }
        }

        if (lastVoted[_user] < _time) {
            _totalWeight = 0;
        }
        totalWeightsPerEpoch[_time] -= _totalWeight;
    }

    /// @notice check if user can vote
    function _voteDelay(address _user) internal view {
        require(block.timestamp > lastVoted[_user] + VOTE_DELAY, "ERR: VOTE_DELAY");
    }

    function addPool(address _pool) external onlyOwner {
        require(!poolAdded[_pool], "Already added");
        pools.push(_pool);
        poolAdded[_pool] = true;
    }

    function _epochTimestamp() internal view returns (uint256) {
        return block.timestamp / 1 weeks * 1 weeks;
    }

    function setPoolState(address _pool, bool _state) external onlyOwner {
        if (poolAdded[_pool]) {
            isAlive[_pool] = _state;
        }
    }

    function getPoolVote(address _user) external view returns (address[] memory) {
        return poolVote[_user];
    }

    function getPools() external view returns (address[] memory) {
        return pools;
    }

    function getPoolWeightPerEpoch(uint256 _timestamp, address _pool) external view returns (uint256) {
        return weightsPerEpoch[_timestamp][_pool];
    }
}