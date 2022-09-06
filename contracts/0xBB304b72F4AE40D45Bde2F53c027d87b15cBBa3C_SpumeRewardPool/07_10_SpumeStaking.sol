// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 


import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";


error TransferFailed();
error NeedsMoreThanZero();


contract SpumeStaking is ReentrancyGuard, Ownable, Pausable { 
    // Varriables 
    using SafeERC20 for IERC20;
    IERC20 public s_rewardsToken;
    IERC20 public s_stakingToken;
    uint256 public constant REWARD_RATE = 100000000;
    uint256 public s_lastUpdateTime;
    uint256 public s_rewardPerTokenStaked;
    uint256 public s_createdAt;
    uint256 public s_totalSupply;

    // Mappings 
    mapping(address => uint256) public s_userRewardPerTokenPaid; 
    mapping(address => uint256) public s_rewards; 
    mapping(address => uint256) public s_balances; 

    //Events 
    event Staked(address indexed user, uint256 indexed amount);
    event WithdrewStake(address indexed user, uint256 indexed amount);
    event RewardsClaimed(address indexed user, uint256 indexed amount);
    event Deposited(uint256 indexed amount);

    constructor(address stakingToken, address rewardsToken) {
        s_stakingToken = IERC20(stakingToken); //Spume Address 
        s_rewardsToken = IERC20(rewardsToken); //Spume Reward Address 
        s_createdAt = block.timestamp;
    }

    /*
     * Modifiers
     */
    modifier updateReward(address account) {
        s_rewardPerTokenStaked = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStaked;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert NeedsMoreThanZero();
        }
        _;
    }

    /*
     * @notice Deposit Spume tokens into this contract
     * @param amount | How much to stake
     */
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        nonReentrant
        moreThanZero(amount)
        whenNotPaused
    {
        s_totalSupply += amount;
        s_balances[msg.sender] += amount;
        emit Staked(msg.sender, amount);
        s_stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /*
     * @notice Withdraw Spume tokens from this contract
     * @param amount | How much to withdraw
     */
    function unstake(uint256 amount) external updateReward(msg.sender) nonReentrant whenNotPaused {
        require(s_balances[msg.sender] >= amount, "You cannot unstake that much");
        s_totalSupply -= amount;
        s_balances[msg.sender] -= amount;
        emit WithdrewStake(msg.sender, amount);
        s_stakingToken.safeTransfer(msg.sender, amount);
    }

    /*
     * @notice How much reward a user has earned
     * @param account | The account to check the earned for 
     */
    function earned(address account) public view returns (uint256) {
        return
            ((s_balances[account] * (rewardPerToken() - s_userRewardPerTokenPaid[account])) /
                1e18) + s_rewards[account];
    }

    /*
     * @notice How many reward tokens user gets based on how long Spume has been staked during which "snapshots"
     */
    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStaked;
        }
        return
            s_rewardPerTokenStaked +
            (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
    }

    /*
     * @notice User claims their reward tokens
     * @param account | The account to claim the reward for 
     */
    function claimReward(address claimer) external updateReward(claimer) whenNotPaused nonReentrant returns (uint256) {
        uint256 reward = s_rewards[claimer];
        s_rewards[claimer] = 0;
        emit RewardsClaimed(claimer, reward); 
        s_rewardsToken.safeTransfer(claimer, reward);
        return reward; 
    }

    /*
     * @notice Get staked amount for an account
     * @param account | The account to get the staked amount for 
     */ 
    function getStaked(address account) external view returns (uint256) {
        return s_balances[account];
    }

    /*
     * @notice Get time crated at 
     */ 
    function getCreatedAt() external view returns (uint256) {
        return s_createdAt;
    }

    /*
     * @notice Get Staked total Supply  
     */ 
    function getStakedTotalSupply() external view returns (uint256) {
        return s_totalSupply;
    }

    /*
     * @notice Pauses Contract 
     */
    function pauseSpumeStaking() external onlyOwner whenNotPaused {
        _pause(); 
    }

    /*
     * @notice Unpauses Contract 
     */
    function unPauseSpumeStaking() external onlyOwner whenPaused {
        _unpause(); 
    }
    
}