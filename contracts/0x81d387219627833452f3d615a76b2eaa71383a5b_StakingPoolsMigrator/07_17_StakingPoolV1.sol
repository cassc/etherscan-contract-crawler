// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

import "./StakingPoolV1Owned.sol";
import "./StakingPoolV1Pausable.sol";

contract StakingPoolV1 is ReentrancyGuard, StakingPoolV1Owned, StakingPoolV1Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function getTime() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    uint256 public minStakeBalance = 1 * _convertDecimalTokenBalance;
    uint256 public rewardPerIntervalDivider = 411;
    IERC20 public stakingToken;
    address[] public allAddress;

    uint256 internal rewardInterval = 86400 * 1; // 1 day
    uint256 internal unstakingInterval = 86400 * 8; // 8 day
    // uint256 internal rewardInterval = 1 minutes;
    // uint256 internal unstakingInterval = 8 minutes;

    uint256 private _convertDecimalTokenBalance = 10**18;
    uint256 private rewardDistributorBalance = 0;
    uint256 private _totalSupply;
    mapping(address => uint256) private _addressToIndex;
    mapping(address => uint256) private _rewardBalance;
    mapping(address => uint256) private _stakedBalance;
    mapping(address => uint256) private _stakedTime;
    mapping(address => uint256) private _unstakingBalance;
    mapping(address => uint256) private _unstakingTime;

    /// @dev How much OM is available to distribute from reward disributor address
    function rewardDistributorBalanceOf() external view returns (uint256) {
        return rewardDistributorBalance;
    }

    /// @dev How much OM is in the contract total
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @dev How much have the address earned
    function rewardBalanceOf(address account) external view returns (uint256) {
        return _rewardBalance[account];
    }

    /// @dev How much OM has address staked
    function balanceOf(address account) external view returns (uint256) {
        return _stakedBalance[account];
    }

    /// @dev When did user stake
    function stakeTime(address account) external view returns (uint256) {
        return _stakedTime[account];
    }

    /// @dev How much OM is unstaking in the address's current unstaking procedure
    function unstakingBalanceOf(address account) external view returns (uint256) {
        return _unstakingBalance[account];
    }

    /// @dev How much time is left in the address's current unstaking procedure
    function unstakingTimeOf(address account) external view returns (uint256) {
        return _unstakingTime[account];
    }

    /// @dev When is the address's next reward going to become unstakable
    function nextRewardApplicableTime(address account) external view returns (uint256) {
        require(_stakedTime[account] != 0, "You dont have a stake in progress");
        require(_stakedTime[account] <= getTime(), "Your stake takes 24 hours to become available to interact with");
        uint256 secondsRemaining = (getTime() - _stakedTime[account]).mod(rewardInterval);
        return secondsRemaining;
    }

    function perIntervalRewardOf(address account) public view returns (uint256) {
        return _stakedBalance[account].div(rewardPerIntervalDivider);
    }

    function stakedIntervalsCountOf(address account) public view returns (uint256) {
        if (_stakedTime[account] == 0) return 0;
        uint256 diffTime = getTime().sub(_stakedTime[account]);
        return diffTime.div(rewardInterval);
    }

    /// @dev How much has account earned. Account's potential rewards ready to begin unstaking
    function earned(address account) public view returns (uint256) {
        uint256 perIntervalReward = perIntervalRewardOf(account);
        uint256 intervalsStaked = stakedIntervalsCountOf(account);
        return perIntervalReward.mul(intervalsStaked);
    }

    function getAddresses(uint256 i) public view returns (address) {
        return allAddress[i];
    }

    event Recovered(address token, uint256 amount);
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardWithdrawn(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _owner, IERC20 _stakingToken) public StakingPoolV1Owned(_owner) {
        stakingToken = _stakingToken;
    }

    function stake(uint256 amount) external nonReentrant notPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        uint256 newStakedBalance = _stakedBalance[msg.sender].add(amount);
        require(newStakedBalance >= minStakeBalance, "Staked balance is less than minimum stake balance");
        uint256 currentTimestamp = getTime();
        _stakedBalance[msg.sender] = newStakedBalance;
        _stakedTime[msg.sender] = currentTimestamp;
        _totalSupply = _totalSupply.add(amount);
        if (_addressToIndex[msg.sender] == 0) {
            allAddress.push(msg.sender);
            uint256 index = allAddress.length;
            _addressToIndex[msg.sender] = index;
        }
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public updateReward(msg.sender) {
        _unstake(msg.sender, amount);
    }

    /// @dev Allows user to unstake tokens without (or with partial) rewards in case of empty reward distribution pool
    function exit() public {
        uint256 reward = Math.min(earned(msg.sender), rewardDistributorBalance);
        require(reward > 0 || _rewardBalance[msg.sender] > 0 || _stakedBalance[msg.sender] > 0, "No tokens to exit");
        _addReward(msg.sender, reward);
        _stakedTime[msg.sender] = 0;
        if (_rewardBalance[msg.sender] > 0) withdrawReward();
        if (_stakedBalance[msg.sender] > 0) _unstake(msg.sender, _stakedBalance[msg.sender]);
    }

    function withdrawUnstakedBalance(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Account does not have an unstaking balance");
        require(_unstakingBalance[msg.sender] >= amount, "Account does not have that much balance unstaked");
        require(_unstakingTime[msg.sender] <= getTime(), "Unstaking period has not finished yet");
        _unstakingBalance[msg.sender] = _unstakingBalance[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function lockInReward() public updateReward(msg.sender) {}

    function lockInRewardOnBehalf(address _address) private updateReward(_address) {}

    function withdrawReward() public updateReward(msg.sender) {
        uint256 reward = _rewardBalance[msg.sender];
        require(reward > 0, "You have not earned any rewards yet");
        _rewardBalance[msg.sender] = 0;
        _unstakingBalance[msg.sender] = _unstakingBalance[msg.sender].add(reward);
        _unstakingTime[msg.sender] = getTime() + unstakingInterval;
        emit RewardWithdrawn(msg.sender, reward);
    }

    function stakeReward() public updateReward(msg.sender) {
        require(_rewardBalance[msg.sender] > 0, "You have not earned any rewards yet");
        _stakedBalance[msg.sender] = _stakedBalance[msg.sender].add(_rewardBalance[msg.sender]);
        _rewardBalance[msg.sender] = 0;
    }

    function addRewardSupply(uint256 amount) external onlyOwner {
        require(amount > 0, "Cannot add 0 tokens");
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        rewardDistributorBalance = rewardDistributorBalance.add(amount);
        _totalSupply = _totalSupply.add(amount);
    }

    function removeRewardSupply(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= rewardDistributorBalance, "rewardDistributorBalance has less tokens than requested");
        require(amount <= _totalSupply, "Amount is greater that total supply");
        stakingToken.safeTransfer(owner, amount);
        rewardDistributorBalance = rewardDistributorBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);
    }

    function setRewardsInterval(uint256 _rewardInterval) external onlyOwner {
        require(
            _rewardInterval >= 1 && _rewardInterval <= 365,
            "Staking reward interval must be between 1 and 365 inclusive"
        );
        uint256 length = allAddress.length;
        for (uint256 i = 0; i < length; i++) lockInRewardOnBehalf(allAddress[i]);
        rewardInterval = _rewardInterval * 1 days;
        emit RewardsDurationUpdated(rewardInterval);
    }

    function setRewardsDivider(uint256 _rewardPerIntervalDivider) external onlyOwner {
        require(_rewardPerIntervalDivider >= 411, "Reward can only be lowered, divider must be greater than 410");
        uint256 length = allAddress.length;
        for (uint256 i = 0; i < length; i++) lockInRewardOnBehalf(allAddress[i]);
        rewardPerIntervalDivider = _rewardPerIntervalDivider;
    }

    /// @param _minStakeBalance count of min tokens values
    /// @dev to set min staking balance to 2 need to pass 2000000000000000000 as argument (if ERC20's decimals is 18).
    function setMinStakeBalance(uint256 _minStakeBalance) external onlyOwner {
        minStakeBalance = _minStakeBalance;
    }

    function _addReward(address account, uint256 amount) private {
        if (amount == 0) return;
        rewardDistributorBalance = rewardDistributorBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        _rewardBalance[account] = _rewardBalance[account].add(amount);
        emit RewardPaid(account, amount);
    }

    function _unstake(address account, uint256 amount) private {
        require(_stakedBalance[account] > 0, "Account does not have a balance staked");
        require(amount > 0, "Cannot unstake Zero OM");
        require(amount <= _stakedBalance[account], "Attempted to withdraw more than balance staked");
        _stakedBalance[account] = _stakedBalance[account].sub(amount);
        if (_stakedBalance[account] == 0) _stakedTime[account] = 0;
        else {
            require(
                _stakedBalance[account] >= minStakeBalance,
                "Your remaining staked balance would be under the minimum stake. Either leave at least 10 OM in the staking pool or withdraw all your OM"
            );
        }
        _unstakingBalance[account] = _unstakingBalance[account].add(amount);
        _unstakingTime[account] = getTime() + unstakingInterval;
        emit Unstaked(account, amount);
    }

    /// @dev If their _stakeTime is 0, this means they arent active in the system
    modifier updateReward(address account) {
        if (_stakedTime[account] > 0) {
            uint256 stakedIntervals = stakedIntervalsCountOf(account);
            uint256 perIntervalReward = perIntervalRewardOf(account);
            uint256 reward = stakedIntervals.mul(perIntervalReward);
            require(reward <= rewardDistributorBalance, "Rewards pool is extinguished");
            _addReward(account, reward);
            _stakedTime[account] = _stakedTime[account].add(rewardInterval.mul(stakedIntervals));
        }
        _;
    }
}