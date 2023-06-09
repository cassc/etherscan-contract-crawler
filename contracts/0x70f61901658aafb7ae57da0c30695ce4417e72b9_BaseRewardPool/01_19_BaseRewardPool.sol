// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./Interfaces/IBaseRewardPool.sol";
import "./Interfaces/IPendleBooster.sol";
import "@shared/lib-contracts-v0.8/contracts/Dependencies/TransferHelper.sol";

contract BaseRewardPool is IBaseRewardPool, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    using TransferHelper for address;

    address public booster;
    uint256 public pid;

    IERC20 public stakingToken;
    address[] public rewardTokens;

    uint256 public constant duration = 7 days;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
    }

    struct UserReward {
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }

    mapping(address => Reward) public rewards;
    mapping(address => bool) public isRewardToken;

    mapping(address => mapping(address => UserReward)) public userRewards;

    mapping(address => uint256) public userLastTime;

    mapping(address => uint256) public userAmountTime;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ZAP_ROLE = keccak256("ZAP_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _booster) public initializer {
        require(_booster != address(0), "invalid _booster!");

        __AccessControl_init();

        booster = _booster;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, _booster);

        emit BoosterUpdated(_booster);
    }

    function setParams(
        uint256 _pid,
        address _stakingToken,
        address _rewardToken
    ) external override {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == booster,
            "!auth"
        );

        require(
            address(stakingToken) == address(0),
            "params have already been set"
        );

        require(_stakingToken != address(0), "invalid _stakingToken!");
        require(_rewardToken != address(0), "invalid _rewardToken!");

        pid = _pid;
        stakingToken = IERC20(_stakingToken);

        addRewardToken(_rewardToken);
    }

    function addRewardToken(address _rewardToken) internal {
        require(_rewardToken != address(0), "invalid _rewardToken!");
        if (isRewardToken[_rewardToken]) {
            return;
        }
        rewardTokens.push(_rewardToken);
        isRewardToken[_rewardToken] = true;

        emit RewardTokenAdded(_rewardToken);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    modifier updateReward(address _account) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            Reward storage reward = rewards[rewardToken];
            reward.rewardPerTokenStored = rewardPerToken(rewardToken);
            reward.lastUpdateTime = lastTimeRewardApplicable(rewardToken);

            UserReward storage userReward = userRewards[_account][rewardToken];
            userReward.rewards = earned(_account, rewardToken);
            userReward.userRewardPerTokenPaid = rewards[rewardToken]
                .rewardPerTokenStored;
        }

        userAmountTime[_account] = getUserAmountTime(_account);
        userLastTime[_account] = block.timestamp;

        _;
    }

    function getRewardTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return rewardTokens;
    }

    function getRewardTokensLength() external view override returns (uint256) {
        return rewardTokens.length;
    }

    function lastTimeRewardApplicable(
        address _rewardToken
    ) public view returns (uint256) {
        return Math.min(block.timestamp, rewards[_rewardToken].periodFinish);
    }

    function rewardPerToken(
        address _rewardToken
    ) public view returns (uint256) {
        Reward memory reward = rewards[_rewardToken];
        if (totalSupply() == 0) {
            return reward.rewardPerTokenStored;
        }
        return
            reward.rewardPerTokenStored +
            (((lastTimeRewardApplicable(_rewardToken) - reward.lastUpdateTime) *
                reward.rewardRate *
                1e18) / totalSupply());
    }

    function earned(
        address _account,
        address _rewardToken
    ) public view override returns (uint256) {
        UserReward memory userReward = userRewards[_account][_rewardToken];
        return
            ((balanceOf(_account) *
                (rewardPerToken(_rewardToken) -
                    userReward.userRewardPerTokenPaid)) / 1e18) +
            userReward.rewards;
    }

    function getUserAmountTime(
        address _account
    ) public view override returns (uint256) {
        uint256 lastTime = userLastTime[_account];
        if (lastTime == 0) {
            return 0;
        }
        uint256 userBalance = _balances[_account];
        if (userBalance == 0) {
            return userAmountTime[_account];
        }
        return
            userAmountTime[_account] +
            ((block.timestamp - lastTime) * userBalance);
    }

    function stake(uint256 _amount) public override updateReward(msg.sender) {
        require(_amount > 0, "RewardPool : Cannot stake 0");

        _totalSupply = _totalSupply + _amount;
        _balances[msg.sender] = _balances[msg.sender] + _amount;

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function stakeAll() external override {
        uint256 balance = stakingToken.balanceOf(msg.sender);
        stake(balance);
    }

    function stakeFor(
        address _for,
        uint256 _amount
    ) external override updateReward(_for) {
        require(_for != address(0), "invalid _for!");
        require(_amount > 0, "RewardPool : Cannot stake 0");

        //give to _for
        _totalSupply = _totalSupply + _amount;
        _balances[_for] = _balances[_for] + _amount;

        //take away from sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(_for, _amount);
    }

    function withdraw(uint256 amount) external override {
        _withdraw(msg.sender, amount, true);
    }

    function withdrawAll() external override {
        _withdraw(msg.sender, _balances[msg.sender], true);
    }

    function withdrawFor(
        address _account,
        uint256 _amount
    ) external override onlyRole(ZAP_ROLE) {
        _withdraw(_account, _amount, true);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        uint256 _amount = _balances[msg.sender];
        _withdraw(msg.sender, _amount, false);

        emit EmergencyWithdrawn(msg.sender, _amount);
    }

    function _withdraw(
        address _account,
        uint256 _amount,
        bool _reward
    ) internal updateReward(_account) {
        require(_amount > 0, "RewardPool : Cannot withdraw 0");

        _totalSupply = _totalSupply - _amount;
        _balances[_account] = _balances[_account] - _amount;

        stakingToken.safeTransfer(_account, _amount);
        emit Withdrawn(_account, _amount);

        if (_reward) {
            _getReward(_account);
        }
    }

    function getReward(
        address _account
    ) public override updateReward(_account) {
        _getReward(_account);
    }

    function _getReward(address _account) internal {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 reward = userRewards[_account][rewardToken].rewards;
            if (reward > 0) {
                userRewards[_account][rewardToken].rewards = 0;
                rewardToken.safeTransferToken(_account, reward);
                IPendleBooster(booster).rewardClaimed(
                    pid,
                    _account,
                    rewardToken,
                    reward
                );
                emit RewardPaid(_account, rewardToken, reward);
            }
        }
    }

    function donate(
        address _rewardToken,
        uint256 _amount
    ) external payable override {
        require(isRewardToken[_rewardToken], "invalid token");
        if (AddressLib.isPlatformToken(_rewardToken)) {
            require(_amount == msg.value, "invalid amount");
        } else {
            require(msg.value == 0, "invalid msg.value");
            IERC20(_rewardToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }

        rewards[_rewardToken].queuedRewards =
            rewards[_rewardToken].queuedRewards +
            _amount;
    }

    function queueNewRewards(
        address _rewardToken,
        uint256 _rewards
    ) external payable override onlyRole(ADMIN_ROLE) {
        addRewardToken(_rewardToken);

        if (AddressLib.isPlatformToken(_rewardToken)) {
            require(_rewards == msg.value, "invalid amount");
        } else {
            require(msg.value == 0, "invalid msg.value");
            IERC20(_rewardToken).safeTransferFrom(
                msg.sender,
                address(this),
                _rewards
            );
        }

        Reward storage rewardInfo = rewards[_rewardToken];

        if (totalSupply() == 0) {
            rewardInfo.queuedRewards = rewardInfo.queuedRewards + _rewards;
            return;
        }

        rewardInfo.rewardPerTokenStored = rewardPerToken(_rewardToken);

        _rewards = _rewards + rewardInfo.queuedRewards;
        rewardInfo.queuedRewards = 0;

        if (block.timestamp >= rewardInfo.periodFinish) {
            rewardInfo.rewardRate = _rewards / duration;
        } else {
            uint256 remaining = rewardInfo.periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardInfo.rewardRate;
            _rewards = _rewards + leftover;
            rewardInfo.rewardRate = _rewards / duration;
        }
        rewardInfo.lastUpdateTime = block.timestamp;
        rewardInfo.periodFinish = block.timestamp + duration;
        emit RewardAdded(_rewardToken, _rewards);
    }

    receive() external payable {}
}