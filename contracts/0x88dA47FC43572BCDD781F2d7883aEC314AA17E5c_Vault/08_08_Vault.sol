// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";

contract Vault is Owned, ReentrancyGuard, Pausable {
    using SafeTransferLib for ERC20;
    uint private constant MULTIPLIER = 1e18;        // multiplier for 18 decimals

    address public immutable stakeTokenAddr;        // shopx token address
    uint256 public totalSupply;                     // total number of shopx tokens staked
    mapping(address => uint) public lockTime;       // lockup time for each user
    mapping(address => uint256) public balanceOf;   // token balance of each user
    uint256 public defaultLockTime = 90 days;       // default lockTime
    uint256 public maxStake = 500_000 ether;        // maximum shopx allowed to stake for each user: 500,000 SHOPX
    uint256 public minStake = 1_000 ether;          // minimum shopx allowed to stake: 1,000 SHOPX

    address public immutable rewardTokenAddr;       // reward token address
    uint256 private rewardIndex;                    // index to calculate rewards
    mapping(address => uint) private rewardIndexOf; // reward index of each user
    mapping(address => uint256) public earned;      // reward by address

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardWithdrawn(address indexed user, uint256 reward);
    event Deposited(address indexed admin, uint256 amount);
    event UpdateDefaultLockTime(uint256 defaultLockTime);
    event UpdateMaxStake(uint256 maxStake);
    event UpdateMinStake(uint256 minStake);

    error MaxStake();
    error MinStake();

    constructor(address _stakeTokenAddr, address _rewardTokenAddr) Owned(msg.sender) {
        stakeTokenAddr = _stakeTokenAddr;
        rewardTokenAddr = _rewardTokenAddr;
    }

    receive() external payable {
        revert("Bad Call: send ERC20 reward token to deposit() function.");
    }

    function deposit(uint reward) external {
        require(totalSupply > 0, "totalSupply is 0");
        require(reward > 0, "reward is 0");
        rewardToken().safeTransferFrom(msg.sender, address(this), reward);
        rewardIndex += (reward * MULTIPLIER) / totalSupply;

        emit Deposited(msg.sender, reward);
    }

    function stake(uint256 amount) external whenNotPaused {
        if (amount == 0) return;
        if (amount < minStake) revert MinStake();
        if (balanceOf[msg.sender] + amount > maxStake) revert MaxStake();

        _updateRewards(msg.sender);

        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        // reset lockTime
        lockTime[msg.sender] = block.timestamp + defaultLockTime;

        stakeToken().safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function unstake() external nonReentrant() {
        require(balanceOf[msg.sender] > 0, "Insufficient balance");
        require(block.timestamp > lockTime[msg.sender], "Lock time not expired");

        _updateRewards(msg.sender);

        // withdraw stakeToken
        uint256 accountBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        totalSupply -= accountBalance;
        stakeToken().safeTransfer(msg.sender, accountBalance);

        // withdraw rewardToken
        uint reward = earned[msg.sender];
        if (reward > 0) {
            earned[msg.sender] = 0;
            rewardToken().safeTransfer(msg.sender, reward);
        }

        emit Unstaked(msg.sender, accountBalance, reward);
    }

    function withdrawReward() external nonReentrant() returns (uint) {
        _updateRewards(msg.sender);

        require(earned[msg.sender] > 0, "Insufficient reward");

        uint reward = earned[msg.sender];
        earned[msg.sender] = 0;
        rewardToken().safeTransfer(msg.sender, reward);
        emit RewardWithdrawn(msg.sender, reward);

        return reward;
    }

    function calculateRewardsEarned(address account) external view returns (uint) {
        return earned[account] + _calculateRewards(account);
    }

    function updateDefaultLockTime(uint256 _defaultLockTime) external onlyOwner returns (uint256) {
        require(_defaultLockTime!=0, "Invalid input");
        defaultLockTime = _defaultLockTime;
        emit UpdateDefaultLockTime(defaultLockTime);
        return defaultLockTime;
    }

    function updateMaxStake(uint256 _maxStake) external onlyOwner returns (uint256) {
        require(_maxStake!=0, "Invalid input");
        maxStake = _maxStake;
        emit UpdateMaxStake(maxStake);
        return maxStake;
    }

    function updateMinStake(uint256 _minStake) external onlyOwner returns (uint256) {
        // minStake = 0 to disable the minimum stake amount
        minStake = _minStake;
        emit UpdateMinStake(_minStake);
        return minStake;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function stakeToken() public view returns (ERC20 _stakeToken) {
        return ERC20(stakeTokenAddr);
    }

    function rewardToken() public view returns (ERC20 _rewardToken) {
        return ERC20(rewardTokenAddr);
    }

    function _calculateRewards(address account) private view returns (uint) {
        uint shares = balanceOf[account];
        return (shares * (rewardIndex - rewardIndexOf[account])) / MULTIPLIER;
    }

    function _updateRewards(address account) private {
        earned[account] += _calculateRewards(account);
        rewardIndexOf[account] = rewardIndex;
    }
}