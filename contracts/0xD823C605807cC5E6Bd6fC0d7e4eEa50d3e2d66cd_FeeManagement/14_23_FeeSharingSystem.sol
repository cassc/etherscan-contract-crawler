// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import {TokenDistributor} from './TokenDistributor.sol';
import {IStakeFor} from './IStakeFor.sol';

/**
 * @title FeeSharingSystem
 * @notice It handles the distribution of fees using
 * WETH along with the auto-compounding of X2Y2.
 */
contract FeeSharingSystem is ReentrancyGuard, AccessControl, IStakeFor {
    using SafeERC20 for IERC20;

    // for `depositFor` call
    bytes32 public constant DEPOSIT_ROLE = keccak256('DEPOSIT_ROLE');

    // for `updateRewards()`
    bytes32 public constant REWARD_UPDATE_ROLE = keccak256('REWARD_UPDATE_ROLE');

    struct UserInfo {
        uint256 shares; // shares of token staked
        uint256 userRewardPerTokenPaid; // user reward per token paid
        uint256 rewards; // pending rewards
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    IERC20 public immutable x2y2Token;

    IERC20 public immutable rewardToken;

    TokenDistributor public immutable tokenDistributor;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last reward adjustment block number
    uint256 public lastRewardAdjustment;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalShares;

    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, uint256 harvestedAmount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(uint256 numberBlocks, uint256 rewardPerBlock, uint256 reward);
    event Withdraw(address indexed user, uint256 amount, uint256 harvestedAmount);

    /**
     * @notice Constructor
     * @param _x2y2Token address of the token staked
     * @param _rewardToken address of the reward token
     * @param _tokenDistributor address of the token distributor contract
     */
    constructor(
        address _x2y2Token,
        address _rewardToken,
        address _tokenDistributor
    ) {
        rewardToken = IERC20(_rewardToken);
        x2y2Token = IERC20(_x2y2Token);
        tokenDistributor = TokenDistributor(_tokenDistributor);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice deposit on behalf of `user`, must be called on fresh deposit only
     * @param user deposit user
     * @param amount amount to deposit
     */
    function depositFor(address user, uint256 amount)
        external
        override
        nonReentrant
        onlyRole(DEPOSIT_ROLE)
        returns (bool)
    {
        require(amount >= PRECISION_FACTOR, 'Deposit: Amount must be >= 1 X2Y2');

        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(user);

        // Retrieve total amount staked by this contract
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // transfer stakingToken from **sender**
        x2y2Token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentShares;

        // Calculate the number of shares to issue for the user
        if (totalShares != 0) {
            currentShares = (amount * totalShares) / totalAmountStaked;
            // This is a sanity check to prevent deposit for 0 shares
            require(currentShares != 0, 'Deposit: Fail');
        } else {
            currentShares = amount;
        }

        // Adjust internal shares
        userInfo[user].shares += currentShares;
        totalShares += currentShares;

        // Verify X2Y2 token allowance and adjust if necessary
        _checkAndAdjustX2Y2TokenAllowanceIfRequired(amount, address(tokenDistributor));

        // Deposit user amount in the token distributor contract
        tokenDistributor.deposit(amount);

        emit Deposit(user, amount, 0);

        return true;
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     * @param amount amount to deposit (in X2Y2)
     * @param claimRewardToken whether to claim reward tokens
     * @dev There is a limit of 1 X2Y2 per deposit to prevent potential manipulation of current shares
     */
    function deposit(uint256 amount, bool claimRewardToken) external nonReentrant {
        require(amount >= PRECISION_FACTOR, 'Deposit: Amount must be >= 1 X2Y2');

        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve total amount staked by this contract
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Transfer X2Y2 tokens to this address
        x2y2Token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 currentShares;

        // Calculate the number of shares to issue for the user
        if (totalShares != 0) {
            currentShares = (amount * totalShares) / totalAmountStaked;
            // This is a sanity check to prevent deposit for 0 shares
            require(currentShares != 0, 'Deposit: Fail');
        } else {
            currentShares = amount;
        }

        // Adjust internal shares
        userInfo[msg.sender].shares += currentShares;
        totalShares += currentShares;

        uint256 pendingRewards;

        if (claimRewardToken) {
            // Fetch pending rewards
            pendingRewards = userInfo[msg.sender].rewards;

            if (pendingRewards > 0) {
                userInfo[msg.sender].rewards = 0;
                rewardToken.safeTransfer(msg.sender, pendingRewards);
            }
        }

        // Verify X2Y2 token allowance and adjust if necessary
        _checkAndAdjustX2Y2TokenAllowanceIfRequired(amount, address(tokenDistributor));

        // Deposit user amount in the token distributor contract
        tokenDistributor.deposit(amount);

        emit Deposit(msg.sender, amount, pendingRewards);
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function harvest() external nonReentrant {
        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve pending rewards
        uint256 pendingRewards = userInfo[msg.sender].rewards;

        // If pending rewards are null, revert
        require(pendingRewards > 0, 'Harvest: Pending rewards must be > 0');

        // Adjust user rewards and transfer
        userInfo[msg.sender].rewards = 0;

        // Transfer reward token to sender
        rewardToken.safeTransfer(msg.sender, pendingRewards);

        emit Harvest(msg.sender, pendingRewards);
    }

    /**
     * @notice Withdraw staked tokens (and collect reward tokens if requested)
     * @param shares shares to withdraw
     * @param claimRewardToken whether to claim reward tokens
     */
    function withdraw(uint256 shares, bool claimRewardToken) external nonReentrant {
        require(
            (shares > 0) && (shares <= userInfo[msg.sender].shares),
            'Withdraw: Shares equal to 0 or larger than user shares'
        );

        _withdraw(shares, claimRewardToken);
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     * @param claimRewardToken whether to claim reward tokens
     */
    function withdrawAll(bool claimRewardToken) external nonReentrant {
        _withdraw(userInfo[msg.sender].shares, claimRewardToken);
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(uint256 reward, uint256 rewardDurationInBlocks)
        external
        onlyRole(REWARD_UPDATE_ROLE)
    {
        // Adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = reward / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (reward + ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        emit NewRewardPeriod(rewardDurationInBlocks, currentRewardPerBlock, reward);
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user) external view returns (uint256) {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Calculate value of X2Y2 for a user given a number of shares owned
     * @param user address of the user
     */
    function calculateSharesValueInX2Y2(address user) external view returns (uint256) {
        // Retrieve amount staked
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Adjust for pending rewards
        totalAmountStaked += tokenDistributor.calculatePendingRewards(address(this));

        // Return user pro-rata of total shares
        return
            userInfo[user].shares == 0
                ? 0
                : (totalAmountStaked * userInfo[user].shares) / totalShares;
    }

    /**
     * @notice Calculate price of one share (in X2Y2 token)
     * Share price is expressed times 1e18
     */
    function calculateSharePriceInX2Y2() external view returns (uint256) {
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));

        // Adjust for pending rewards
        totalAmountStaked += tokenDistributor.calculatePendingRewards(address(this));

        return
            totalShares == 0
                ? PRECISION_FACTOR
                : (totalAmountStaked * PRECISION_FACTOR) / (totalShares);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user) internal view returns (uint256) {
        return
            ((userInfo[user].shares *
                (_rewardPerToken() - (userInfo[user].userRewardPerTokenPaid))) / PRECISION_FACTOR) +
            userInfo[user].rewards;
    }

    /**
     * @notice Check current allowance and adjust if necessary
     * @param _amount amount to transfer
     * @param _to token to transfer
     */
    function _checkAndAdjustX2Y2TokenAllowanceIfRequired(uint256 _amount, address _to) internal {
        if (x2y2Token.allowance(address(this), _to) < _amount) {
            x2y2Token.approve(_to, type(uint256).max);
        }
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per token
     */
    function _rewardPerToken() internal view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock * PRECISION_FACTOR)) /
            totalShares;
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerToken();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens (and collect reward tokens if requested)
     * @param shares shares to withdraw
     * @param claimRewardToken whether to claim reward tokens
     */
    function _withdraw(uint256 shares, bool claimRewardToken) internal {
        // Auto compounds for everyone
        tokenDistributor.harvestAndCompound();

        // Update reward for user
        _updateReward(msg.sender);

        // Retrieve total amount staked and calculated current amount (in X2Y2)
        (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(this));
        uint256 currentAmount = (totalAmountStaked * shares) / totalShares;

        userInfo[msg.sender].shares -= shares;
        totalShares -= shares;

        // Withdraw amount equivalent in shares
        tokenDistributor.withdraw(currentAmount);

        uint256 pendingRewards;

        if (claimRewardToken) {
            // Fetch pending rewards
            pendingRewards = userInfo[msg.sender].rewards;

            if (pendingRewards > 0) {
                userInfo[msg.sender].rewards = 0;
                rewardToken.safeTransfer(msg.sender, pendingRewards);
            }
        }

        // Transfer X2Y2 tokens to sender
        x2y2Token.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, pendingRewards);
    }
}