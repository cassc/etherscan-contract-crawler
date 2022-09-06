// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./libraries/Math.sol";
import "./utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable not-rely-on-time
contract PicniqSingleStake is Context {

    IERC20 internal immutable _token;

    RewardState private _state;

    uint256 private _totalSupply;
    mapping(address => uint256) private _userRewardPerTokenPaid;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _balances;

    struct RewardState {
        uint8 mutex;
        uint64 periodFinish;
        uint64 rewardsDuration;
        uint64 lastUpdateTime;
        uint160 distributor;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
    }

    constructor(
        address token,
        address distributor,
        uint64 duration
    ) {
        _state.mutex = 1;
        _state.rewardsDuration = duration;
        _token = IERC20(token);
        _state.distributor = uint160(distributor);
    }

    function rewardToken() external view returns (address) {
        return address(_token);
    }

    function stakingToken() external view returns (address) {
        return address(_token);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, _state.periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        uint256 supply = _totalSupply;

        if (supply == 0) {
            return _state.rewardPerTokenStored;
        }

        return
            _state.rewardPerTokenStored +
            (((lastTimeRewardApplicable() - _state.lastUpdateTime) *
                _state.rewardRate *
                1e18) / supply);
    }

    function earned(address account) public view returns (uint256) {
        return
            (_balances[account] *
                (rewardPerToken() - _userRewardPerTokenPaid[account])) /
            1e18 +
            _rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return _state.rewardRate * _state.rewardsDuration;
    }

    function stake(uint256 amount) external payable updateReward(_msgSender()) {
        require(amount > 0, "Must be greater than 0");

        address sender = _msgSender();

        _token.transferFrom(sender, address(this), amount);

        _totalSupply += amount;
        _balances[sender] += amount;
    }

    function withdraw(uint256 amount) external payable nonReentrant updateReward(_msgSender()) {
        require(amount > 0, "Must be greater than 0");

        address sender = _msgSender();

        _totalSupply -= amount;
        _balances[sender] -= amount;
        _token.transfer(sender, amount);

        emit Withdrawn(sender, amount);
    }

    function getReward() external payable nonReentrant updateReward(_msgSender()) {
        address sender = _msgSender();

        uint256 reward = _rewards[sender];

        if (reward > 0) {
            _rewards[sender] = 0;
            _token.transfer(sender, reward);

            emit RewardPaid(sender, reward);
        }
    }

    function exit() external payable nonReentrant {
        // Logic for updateReward is mixed in for efficiency
        _state.rewardPerTokenStored = rewardPerToken();
        _state.lastUpdateTime = uint64(lastTimeRewardApplicable());

        address sender = _msgSender();

        uint256 reward = earned(sender);
        _userRewardPerTokenPaid[sender] = _state.rewardPerTokenStored;

        uint256 balance = _balances[sender];
        _totalSupply -= balance;
        _balances[sender] = 0;
        _rewards[sender] = 0;

        _token.transfer(sender, balance + reward);

        emit Withdrawn(sender, balance);
        emit RewardPaid(sender, reward);
    }

    function notifyRewardAmount(uint256 reward)
        public
        payable
        onlyDistributor
        updateReward(address(0))
    {
        if (block.timestamp >= _state.periodFinish) {
            _state.rewardRate = reward / _state.rewardsDuration;
        } else {
            uint256 remaining = _state.periodFinish - block.timestamp;
            uint256 leftover = remaining * _state.rewardRate;
            _state.rewardRate =
                (_state.rewardRate + leftover) /
                _state.rewardsDuration;
        }

        uint256 balance = _token.balanceOf(
            address(this)
        ) - _totalSupply;

        require(
            _state.rewardRate <= balance / _state.rewardsDuration,
            "Reward too high"
        );

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + _state.rewardsDuration);

        emit RewardAdded(reward);
    }

    function _notifyRewardAmount(uint256 reward, address account) private {
        _updateReward(account);

        if (block.timestamp >= _state.periodFinish) {
            _state.rewardRate = reward / _state.rewardsDuration;
        } else {
            uint256 remaining = _state.periodFinish - block.timestamp;
            uint256 leftover = remaining * _state.rewardRate;
            _state.rewardRate =
                (_state.rewardRate + leftover) /
                _state.rewardsDuration;
        }

        uint256 balance = _token.balanceOf(
            address(this)
        ) - _totalSupply;

        require(
            _state.rewardRate <= balance / _state.rewardsDuration,
            "Reward too high"
        );

        _state.lastUpdateTime = uint64(block.timestamp);
        _state.periodFinish = uint64(block.timestamp + _state.rewardsDuration);

        emit RewardAdded(reward);
    }

    function _updateReward(address account) private {
        _state.rewardPerTokenStored = rewardPerToken();
        _state.lastUpdateTime = uint64(lastTimeRewardApplicable());

        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = _state.rewardPerTokenStored;
        }
    }

    function addRewardTokens(uint256 amount) external onlyDistributor
    {
        _token.transferFrom(_msgSender(), address(this), amount);
        notifyRewardAmount(amount);
    }

    function withdrawRewardTokens() external onlyDistributor
    {
        require(block.timestamp > _state.periodFinish, "Rewards still active");

        uint256 supply = _totalSupply;
        uint256 balance = _token.balanceOf(address(this));

        _token.transfer(address(_state.distributor), balance - supply);
        
        _notifyRewardAmount(0, address(0));
    }

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    modifier onlyDistributor() {
        require(
            _msgSender() == address(_state.distributor),
            "Must be distributor"
        );
        _;
    }

    modifier nonReentrant() {
        require(_state.mutex == 1, "Nonreentrant");
        _state.mutex = 2;
        _;
        _state.mutex = 1;
    }

    /* === EVENTS === */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}