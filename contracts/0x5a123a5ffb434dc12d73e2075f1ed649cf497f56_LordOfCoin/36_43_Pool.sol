// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILordOfCoin.sol";
import "./interfaces/IDvd.sol";
import "./interfaces/ISDvd.sol";
import "./interfaces/ITreasury.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
abstract contract Pool is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Staked(address indexed sender, address indexed recipient, uint256 amount);
    event Withdrawn(address indexed sender, address indexed recipient, uint256 amount);
    event Claimed(address indexed sender, address indexed recipient, uint256 net, uint256 tax, uint256 total);
    event Halving(uint256 amount);

    /// @dev Token will be DVD or SDVD-ETH UNI-V2
    address public stakedToken;
    ISDvd public sdvd;

    /// @notice Flag to determine if farm is open
    bool public isFarmOpen = false;
    /// @notice Farming will be open on this timestamp
    uint256 public farmOpenTime;

    uint256 public rewardAllocation;
    uint256 public rewardRate;
    uint256 public rewardDuration = 1460 days;  // halving per 4 years
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public finishTime;

    uint256 public bonusRewardAllocation;
    uint256 public bonusRewardRate;
    uint256 public bonusRewardDuration = 1 days; //  Reward bonus distributed every day, must be the same value with pool treasury release threshold
    uint256 public bonusLastUpdateTime;
    uint256 public bonusRewardPerTokenStored;
    uint256 public bonusRewardFinishTime;

    struct AccountInfo {
        // Staked token balance
        uint256 balance;
        // Normal farming reward
        uint256 reward;
        uint256 rewardPerTokenPaid;
        // Bonus reward from transaction fee
        uint256 bonusReward;
        uint256 bonusRewardPerTokenPaid;
    }

    /// @dev Account info
    mapping(address => AccountInfo) public accountInfos;

    /// @dev Total supply of staked tokens
    uint256 private _totalSupply;

    /// @notice Total rewards minted from this pool
    uint256 public totalRewardMinted;

    // @dev Lord of Coin
    address controller;

    // @dev Pool treasury
    address poolTreasury;

    constructor(address _poolTreasury, uint256 _farmOpenTime) public {
        poolTreasury = _poolTreasury;
        farmOpenTime = _farmOpenTime;
    }

    /* ========== Modifiers ========== */

    modifier onlyController {
        require(msg.sender == controller, 'Controller only');
        _;
    }

    modifier onlyPoolTreasury {
        require(msg.sender == poolTreasury, 'Treasury only');
        _;
    }

    modifier farmOpen {
        require(isFarmOpen, 'Farm not open');
        _;
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately
    function init(address _controller, address _stakedToken) external onlyOwner {
        controller = _controller;
        stakedToken = _stakedToken;
        sdvd = ISDvd(ILordOfCoin(_controller).sdvd());

        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Pool Treasury Only ========== */

    /// @notice Distribute bonus rewards to farmers
    /// @dev Can only be called by pool treasury
    function distributeBonusRewards(uint256 amount) external onlyPoolTreasury {
        // Set bonus reward allocation
        bonusRewardAllocation = amount;
        // Calculate bonus reward rate
        bonusRewardRate = bonusRewardAllocation.div(bonusRewardDuration);
        // Set finish time
        bonusRewardFinishTime = block.timestamp.add(bonusRewardDuration);
        // Set last update time
        bonusLastUpdateTime = block.timestamp;
    }

    /* ========== Mutative ========== */

    /// @notice Stake token.
    /// @dev Need to approve staked token first.
    /// @param amount Token amount.
    function stake(uint256 amount) external nonReentrant {
        _stake(msg.sender, msg.sender, amount);
    }

    /// @notice Stake token.
    /// @dev Need to approve staked token first.
    /// @param recipient Address who receive staked token balance.
    /// @param amount Token amount.
    function stakeTo(address recipient, uint256 amount) external nonReentrant {
        _stake(msg.sender, recipient, amount);
    }

    /// @notice Withdraw token.
    /// @param amount Token amount.
    function withdraw(uint256 amount) external nonReentrant farmOpen {
        _withdraw(msg.sender, msg.sender, amount);
    }

    /// @notice Withdraw token.
    /// @param recipient Address who receive staked token.
    /// @param amount Token amount.
    function withdrawTo(address recipient, uint256 amount) external nonReentrant farmOpen {
        _withdraw(msg.sender, recipient, amount);
    }

    /// @notice Claim SDVD reward
    /// @return Reward net amount
    /// @return Reward tax amount
    /// @return Total Reward amount
    function claimReward() external nonReentrant farmOpen returns(uint256, uint256, uint256) {
        return _claimReward(msg.sender, msg.sender);
    }

    /// @notice Claim SDVD reward
    /// @param recipient Address who receive reward.
    /// @return Reward net amount
    /// @return Reward tax amount
    /// @return Total Reward amount
    function claimRewardTo(address recipient) external nonReentrant farmOpen returns(uint256, uint256, uint256) {
        return _claimReward(msg.sender, recipient);
    }

    /* ========== Internal ========== */

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            accountInfos[account].reward = earned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    function _updateBonusReward(address account) internal {
        bonusRewardPerTokenStored = bonusRewardPerToken();
        bonusLastUpdateTime = lastTimeBonusRewardApplicable();
        if (account != address(0)) {
            accountInfos[account].bonusReward = bonusEarned(account);
            accountInfos[account].bonusRewardPerTokenPaid = bonusRewardPerTokenStored;
        }
    }

    /// @notice Stake staked token
    /// @param sender address. Address who have the token.
    /// @param recipient address. Address who receive staked token balance.
    function _stake(address sender, address recipient, uint256 amount) internal virtual {
        _checkOpenFarm();
        _checkHalving();
        _updateReward(recipient);
        _updateBonusReward(recipient);
        _notifyController();

        require(amount > 0, 'Cannot stake 0');

        IERC20(stakedToken).safeTransferFrom(sender, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        accountInfos[recipient].balance = accountInfos[recipient].balance.add(amount);

        emit Staked(sender, recipient, amount);
    }

    /// @notice Withdraw staked token
    /// @param sender address. Address who have stake the token.
    /// @param recipient address. Address who receive the staked token.
    function _withdraw(address sender, address recipient, uint256 amount) internal virtual {
        _checkHalving();
        _updateReward(sender);
        _updateBonusReward(sender);
        _notifyController();

        require(amount > 0, 'Cannot withdraw 0');
        require(accountInfos[sender].balance >= amount, 'Insufficient balance');

        _totalSupply = _totalSupply.sub(amount);
        accountInfos[sender].balance = accountInfos[sender].balance.sub(amount);
        IERC20(stakedToken).safeTransfer(recipient, amount);

        emit Withdrawn(sender, recipient, amount);
    }

    /// @notice Claim reward
    /// @param sender address. Address who have stake the token.
    /// @param recipient address. Address who receive the reward.
    /// @return totalNetReward Total net SDVD reward.
    /// @return totalTaxReward Total taxed SDVD reward.
    /// @return totalReward Total SDVD reward.
    function _claimReward(address sender, address recipient) internal virtual returns(uint256 totalNetReward, uint256 totalTaxReward, uint256 totalReward) {
        _checkHalving();
        _updateReward(sender);
        _updateBonusReward(sender);
        _notifyController();

        uint256 reward = accountInfos[sender].reward;
        uint256 bonusReward = accountInfos[sender].bonusReward;
        totalReward = reward.add(bonusReward);
        require(totalReward > 0, 'No reward to claim');
        if (reward > 0) {
            // Reduce reward first
            accountInfos[sender].reward = 0;

            // Apply tax
            uint256 tax = reward.div(claimRewardTaxDenominator());
            uint256 net = reward.sub(tax);

            // Mint SDVD as reward to recipient
            sdvd.mint(recipient, net);
            // Mint SDVD tax to pool treasury
            sdvd.mint(address(poolTreasury), tax);

            // Increase total
            totalNetReward = totalNetReward.add(net);
            totalTaxReward = totalTaxReward.add(tax);
            // Set stats
            totalRewardMinted = totalRewardMinted.add(reward);
        }
        if (bonusReward > 0) {
            // Reduce bonus reward first
            accountInfos[sender].bonusReward = 0;
            // Get balance and check so we doesn't overrun
            uint256 balance = sdvd.balanceOf(address(this));
            if (bonusReward > balance) {
                bonusReward = balance;
            }

            // Apply tax
            uint256 tax = bonusReward.div(claimRewardTaxDenominator());
            uint256 net = bonusReward.sub(tax);

            // Send bonus reward to recipient
            IERC20(sdvd).safeTransfer(recipient, net);
            // Send tax to treasury
            IERC20(sdvd).safeTransfer(address(poolTreasury), tax);

            // Increase total
            totalNetReward = totalNetReward.add(net);
            totalTaxReward = totalTaxReward.add(tax);
        }
        if (totalReward > 0) {
            emit Claimed(sender, recipient, totalNetReward, totalTaxReward, totalReward);
        }
    }

    /// @notice Check if farm can be open
    function _checkOpenFarm() internal {
        require(farmOpenTime <= block.timestamp, 'Farm not open');
        if (!isFarmOpen) {
            // Set flag
            isFarmOpen = true;

            // Initialize
            lastUpdateTime = block.timestamp;
            finishTime = block.timestamp.add(rewardDuration);
            rewardRate = rewardAllocation.div(rewardDuration);

            // Initialize bonus
            bonusLastUpdateTime = block.timestamp;
            bonusRewardFinishTime = block.timestamp.add(bonusRewardDuration);
            bonusRewardRate = bonusRewardAllocation.div(bonusRewardDuration);
        }
    }

    /// @notice Check and do halving when finish time reached
    function _checkHalving() internal {
        if (block.timestamp >= finishTime) {
            // Halving reward
            rewardAllocation = rewardAllocation.div(2);
            // Calculate reward rate
            rewardRate = rewardAllocation.div(rewardDuration);
            // Set finish time
            finishTime = block.timestamp.add(rewardDuration);
            // Set last update time
            lastUpdateTime = block.timestamp;
            // Emit event
            emit Halving(rewardAllocation);
        }
    }

    /// @notice Check if need to increase snapshot in lord of coin
    function _notifyController() internal {
        ILordOfCoin(controller).checkSnapshot();
        ILordOfCoin(controller).releaseTreasury();
    }

    /* ========== View ========== */

    /// @notice Get staked token total supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get staked token balance
    function balanceOf(address account) external view returns (uint256) {
        return accountInfos[account].balance;
    }

    /// @notice Get full earned amount and bonus
    /// @dev Combine earned
    function fullEarned(address account) external view returns (uint256) {
        return earned(account).add(bonusEarned(account));
    }

    /// @notice Get full reward rate
    /// @dev Combine reward rate
    function fullRewardRate() external view returns (uint256) {
        return rewardRate.add(bonusRewardRate);
    }

    /// @notice Get claim reward tax
    function claimRewardTaxDenominator() public view returns (uint256) {
        if (block.timestamp < farmOpenTime.add(365 days)) {
            // 50% tax
            return 2;
        } else if (block.timestamp < farmOpenTime.add(730 days)) {
            // 33% tax
            return 3;
        } else if (block.timestamp < farmOpenTime.add(1095 days)) {
            // 25% tax
            return 4;
        } else if (block.timestamp < farmOpenTime.add(1460 days)) {
            // 20% tax
            return 5;
        } else {
            // 10% tax
            return 10;
        }
    }

    /// Normal rewards

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, finishTime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            rewardPerToken().sub(accountInfos[account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].reward);
    }

    /// Bonus

    function lastTimeBonusRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, bonusRewardFinishTime);
    }

    function bonusRewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return bonusRewardPerTokenStored;
        }
        return bonusRewardPerTokenStored.add(
            lastTimeBonusRewardApplicable().sub(bonusLastUpdateTime).mul(bonusRewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function bonusEarned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            bonusRewardPerToken().sub(accountInfos[account].bonusRewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].bonusReward);
    }

}