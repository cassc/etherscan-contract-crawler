// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/math/Math.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDZooNFT.sol";
import "./interfaces/IDZooToken.sol";

/**
 * @title DZooStaking
 * @author canokaue & thomgabriel
 * @notice This contract enables users to stake $DZOO tokens in order to earn eggs (unhatched NFTs).
 * @dev Implementation based off of Synthetix' StakingRewards contract.
 * https://docs.synthetix.io/contracts/source/contracts/stakingrewards
 * The idea here is to keep as much as we can from the base staking contract, but instead of yielding
 * tokens we yield NFTs. To accomodate that, rewards need to be tracked separately via an arbitrary
 * "fractional" uint256 value that increase overtime until achieving a "whole" integer and can then
 * be used to claim an egg NFT.
 */
contract DZooStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IDZooToken;

    /* ========== STATE VARIABLES ========== */

    /// @notice Address of the rewards token (NFT)
    IDZooNFT public rewardsToken;
    /// @notice Address of the staking token (DZOO)
    IDZooToken public stakingToken;
    /// @notice fractionalization rate used to track rewards of eggs
    uint256 public constant FRACTIONALIZATION_RATE = 1e18;
    /// @notice maximum amount of eggs a user can claim at once
    uint256 public constant MAX_CLAIMABLE_EGGS = 10;
    /// @notice number of eggs assigned to the staking contract
    uint256 public nftsAssignedtoStake = 0;
    /// @notice number of eggs minted via staking
    uint256 public nftsMintedviaStake = 0;
    /// @notice when the staking contract will be ended. 0 = not finished
    uint256 public periodFinish = 0;
    /// @notice reward rate per second
    uint256 public rewardRate = 0;
    /// @notice duration of the rewards
    uint256 public rewardsDuration = 7 days;
    /// @notice last time reward was updated
    uint256 public lastUpdateTime;
    /// @notice reward per token stored
    uint256 public rewardPerTokenStored;

    /// @notice mapping of user reward per token paid
    mapping(address => uint256) public userRewardPerTokenPaid;
    /// @notice mapping of user rewards
    mapping(address => uint256) public rewards;

    /// @notice amount of tokens staked in the contract
    uint256 private _totalSupply;
    /// @notice mapping of user balances
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */
    /// @notice Deploys the smart contract and sets the rewards and staking tokens
    /// @param _rewardsToken address of the rewards token (NFT)
    /// @param _stakingToken address of the staking token (DZOO)
    constructor(address _rewardsToken, address _stakingToken) {
        require(
            _rewardsToken != address(0),
            "rewards token cannot be zero address"
        );
        require(
            _stakingToken != address(0),
            "staking token cannot be zero address"
        );
        rewardsToken = IDZooNFT(_rewardsToken);
        stakingToken = IDZooToken(_stakingToken);
    }

    /* ========== VIEWS ========== */
    /// @notice total supply of staked tokens
    /// @return total supply of staked tokens
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice rewards supply of staked tokens
    /// @return rewards supply of staked tokens
    function rewardsSupply() external view returns (uint256) {
        return nftsAssignedtoStake - nftsMintedviaStake;
    }

    /// @notice balanceOf of staked tokens of a user
    /// @param account address of the user
    /// @return balanceOf staked tokens of a user
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice last time reward is applicable  computed as the minimum between the current block timestamp and the period finish
    /// @return last time reward is applicable
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice reward per token
    /// @return reward per token
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                FRACTIONALIZATION_RATE) /
            _totalSupply;
    }

    /// @notice earned rewards of a user as staked tokens times the difference between the current reward per token and the user reward per token paid
    /// @param account address of the user
    /// @return earned rewards of a user
    function earned(address account) public view returns (uint256) {
        return
            (_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
            FRACTIONALIZATION_RATE +
            rewards[account];
    }

    /// @notice get reward for duration
    /// @return reward for duration
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice stake tokens
    /// @param amount amount of tokens to stake
    /// @dev permit is used to avoid the need of an approval transaction
    /// emits a Staked event
    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        _balances[msg.sender] += amount;

        // permit
        stakingToken.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice stake DZOO tokens to the Stake smart contract
    /// @param amount amount of tokens to stake
    /// @dev add the staked amount to the total supply and to the user balance
    /// transfer the staked tokens from the user to the smart contract
    /// emits a Staked event
    function stake(
        uint256 amount
    ) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice withdraw DZOO tokens from the Stake smart contract
    /// @param amount amount of tokens to withdraw
    /// @dev substract the staked amount from the total supply and from the user balance
    /// transfer the staked tokens from the smart contract to the user
    /// emits a Withdrawn event
    function withdraw(
        uint256 amount
    ) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(
            amount <= _balances[msg.sender],
            "Cannot withdraw more than balance"
        );
        require(
            amount <= _totalSupply,
            "Cannot withdraw more than total supply"
        );
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice get rewards from the Stake smart contract
    /// @dev transfer the rewards from the smart contract to the user
    /// emits a RewardPaid event
    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward >= FRACTIONALIZATION_RATE, "Cannot claim partial NFT");
        uint256 claimable = (reward - (reward % FRACTIONALIZATION_RATE)) /
            FRACTIONALIZATION_RATE; // whole "integer" of caller's rewards

        if (claimable <= MAX_CLAIMABLE_EGGS) {
            rewards[msg.sender] -= claimable * FRACTIONALIZATION_RATE; // update remainder fractional rewards
        } else {
            claimable = MAX_CLAIMABLE_EGGS;
            rewards[msg.sender] -= MAX_CLAIMABLE_EGGS * FRACTIONALIZATION_RATE; // update remainder fractional rewards
        }
        rewardsToken.mint(msg.sender, claimable);
        nftsMintedviaStake += claimable;
        emit RewardPaid(msg.sender, claimable);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice notify reward amount
    /// @dev Always needs to update the balance of the contract when calling this method
    /// @param nfts amount of NFTs to be rewarded
    /// emits a RewardAdded event
    function notifyRewardAmount(
        uint256 nfts
    ) external onlyOwner updateReward(address(0)) {
        require(nfts <= rewardsToken.MAX_SUPPLY(), "Invalid NFT reward amount");
        // since reward is passed down as whole NFT, we'll multiply it by FRACTIONALIZATION_RATE
        uint256 reward = nfts * FRACTIONALIZATION_RATE;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        // update quantity of NFTs assigned to mint via staking
        nftsAssignedtoStake += nfts;

        // update
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    /// @notice recover ERC20 tokens from the smart contract only owner
    /// @dev only owner can call this method
    /// @param tokenAddress address of the token to be recovered
    /// @param tokenAmount amount of tokens to be recovered
    /// emits a Recovered event
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner nonReentrant {
        require(
            tokenAddress != address(stakingToken),
            "Cannot withdraw the staking token"
        );
        require(
            tokenAddress != address(rewardsToken),
            "Cannot withdraw the rewards token"
        );
        SafeERC20.safeTransfer(IERC20(tokenAddress), owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /// @notice set rewards duration
    /// @dev only owner can call this method
    /// @param _rewardsDuration duration of the rewards
    /// emits a RewardsDurationUpdated event
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        require(_rewardsDuration > 0, "Reward duration can't be zero");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    /// @notice update reward modifier
    /// @dev update the reward of the user
    /// @param account address of the user
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    /// @notice RewardAdded event is emitted when a reward is added
    event RewardAdded(uint256 reward);
    /// @notice Stake event is emitted when a user stakes tokens
    event Staked(address indexed user, uint256 amount);
    /// @notice Withdrawn event is emitted when a user withdraws tokens
    event Withdrawn(address indexed user, uint256 amount);
    /// @notice RewardAdded event is emitted when a reward is added
    event RewardPaid(address indexed user, uint256 reward);
    /// @notice RewardDurationUpdated event is emitted when the rewards duration is updated
    event RewardsDurationUpdated(uint256 newDuration);
    /// @notice Recovered event is emitted when a token is recovered
    event Recovered(address token, uint256 amount);
}