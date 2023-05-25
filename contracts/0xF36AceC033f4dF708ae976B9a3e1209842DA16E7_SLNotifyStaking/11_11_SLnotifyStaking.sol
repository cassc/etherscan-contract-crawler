// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external;
}


contract SLNotifyStaking is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // Interfaces for ERC20 and ERC721
    IERC20 public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(IERC721 _nftCollection, IERC20 _rewardsToken, address _stakingVaultAddress) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        stakingVaultAddress = _stakingVaultAddress;
  
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }
    
    // Staker info
    struct Staker {
        // Amount of tokens staked by the staker
        uint256 amountStaked;

        // Staked token ids
        StakedToken[] stakedTokens;

        // Last time of the rewards were calculated for this user
        uint256 timeOfLastUpdate;

        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
        uint256 lockTime; // added lock time field
    }

    // Address of the staking vault
    address public stakingVaultAddress;

    // Rewards per hour per token deposited in wei.
    uint256 public rewardsPerHour = 5000000000000000000;
    uint256 public rewardsBurnTax = 10;
    uint256 public rewardsVaultTax = 10;
   uint256 public LOCK_TIME = 1209600; // 1 day lock time
   
    // other state variables
    uint256 public totalStaked;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to staker. Made for the SC to remember
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakerAddress;

function stake(uint256[] calldata _tokenIds) external nonReentrant {
    // Get the staker's information from the stakers mapping
    Staker storage staker = stakers[msg.sender];

    // Keep track of the minimum lock time for all tokens being staked
    uint256 minLockTime = 0;

    // Loop through each of the token IDs provided
    for (uint256 i = 0; i < _tokenIds.length; i++) {
        // Check that the staker owns the token they are trying to stake
        require(nftCollection.ownerOf(_tokenIds[i]) == msg.sender, "You don't own this token!");

        // Check that the token is not still locked
        require(staker.lockTime == 0 || block.timestamp >= staker.lockTime, "Token is still locked");

        // If the staker already has tokens staked, calculate and add any unclaimed rewards
        if (staker.amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            staker.unclaimedRewards += rewards;
        }

        // Transfer the token from the staker to the staking contract
        nftCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);

        // Add the token to the staker's list of staked tokens
        staker.stakedTokens.push(StakedToken(msg.sender, _tokenIds[i]));

        // Increment the staker's amount staked
        staker.amountStaked++;

        // Increment the total amount of tokens staked across all stakers
        totalStaked++;

        // Record the staker's address as the owner of the staked token
        stakerAddress[_tokenIds[i]] = msg.sender;

        // Update the minimum lock time for all tokens being staked
        if (minLockTime == 0 || staker.lockTime > block.timestamp + LOCK_TIME) {
            minLockTime = block.timestamp + LOCK_TIME;
        }

        // Update the time of the last staking action for the staker
        staker.timeOfLastUpdate = block.timestamp;
    }

    // Set the lock time for all of the staker's tokens
    staker.lockTime = minLockTime;
}


function withdraw(uint256[] calldata _tokenIds) external nonReentrant {
    Staker storage staker = stakers[msg.sender];
    for (uint256 i = 0; i < _tokenIds.length; i++) {
        require(staker.amountStaked > 0, "You have no tokens staked");
        require(stakerAddress[_tokenIds[i]] == msg.sender, "You don't own this token!");
        uint256 rewards = calculateRewards(msg.sender);
        staker.unclaimedRewards += rewards;
        uint256 index;
        StakedToken[] storage tokens = staker.stakedTokens;
        for (uint256 j = 0; j < tokens.length; j++) {
            if (tokens[j].tokenId == _tokenIds[i] && tokens[j].staker != address(0)) {
                index = j;
                break;
            }
        }
        if (index < tokens.length - 1) {
            tokens[index] = tokens[tokens.length - 1];
        }
        tokens.pop();
        stakerAddress[_tokenIds[i]] = address(0);
        staker.amountStaked--;
        nftCollection.transferFrom(address(this), msg.sender, _tokenIds[i]);
        staker.timeOfLastUpdate = block.timestamp;
    }
}


/**
 * @dev Allows the user to claim their unclaimed rewards. A lock time is set on the staked token, which prevents the user from
 * claiming their rewards until the lock time is over. After the lock time is over, the user can claim their rewards, and the
 * lock time is reset. Rewards are split into three parts: burn tax, vault tax, and user rewards. The burn tax and vault tax are
 * taken from the total rewards, and the remaining amount is transferred to the user. Emits a RewardsClaimed event when the rewards
 * are successfully claimed.
 */
function claimRewards() public nonReentrant whenNotPaused {
    Staker storage staker = stakers[msg.sender];
    require(staker.lockTime == 0 || block.timestamp >= staker.lockTime, "Token is still locked"); // check if tokens are locked
    
    // Calculate and update unclaimed rewards
    uint256 unclaimedRewards = calculateRewards(msg.sender);
    staker.unclaimedRewards += unclaimedRewards;
    
    require(staker.unclaimedRewards > 0, "You have no unclaimed rewards!"); // check if user has unclaimed rewards
    staker.unclaimedRewards = 0;
    uint256 totalRewards = unclaimedRewards;
    staker.lockTime = block.timestamp + LOCK_TIME; // reset lock time
    staker.timeOfLastUpdate = block.timestamp;
    
    if (totalRewards > 0) {
        uint256 burnAmount = totalRewards / rewardsBurnTax; // calculate burn tax
        uint256 stakingVaultAmount = totalRewards / rewardsVaultTax; // calculate vault tax
        
        totalRewards -= burnAmount + stakingVaultAmount; // subtract the total of burn and vault taxes from the total rewards
        
        if (burnAmount > 0) {
            IERC20Burnable(address(rewardsToken)).burn(burnAmount); // burn tokens
        }
        
        if (stakingVaultAmount > 0) {
            rewardsToken.transfer(stakingVaultAddress, stakingVaultAmount); // transfer tokens to the staking vault
        }
        
        rewardsToken.transfer(msg.sender, totalRewards); // transfer remaining tokens to the user
        emit RewardsClaimed(msg.sender, totalRewards); // emit event
    }
}



    //////////
    // View //
    //////////
    

// This function calculates the total available rewards for a given staker
function availableRewards(address staker) public view returns (uint256) {
    // Calculate the rewards that have already been earned but not yet claimed by the staker
    uint256 rewards = calculateRewards(staker) + stakers[staker].unclaimedRewards;
    // Return the total rewards available to the staker
    return rewards;
}

    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {
        // Check if we know this user
        if (stakers[_user].amountStaked > 0) {
            // Return all the tokens in the stakedToken Array for this user that are not -1
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        
        // Otherwise, return empty array
        else {
            return new StakedToken[](0);
        }
    }

    /////////////
    // Internal//
    /////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.

    function setRewardsPerHour(uint256 _rewardsPerHour) public {
        rewardsPerHour = _rewardsPerHour;
    }

    function setBurnTax(uint256 _rewardsBurnTax) public {
        rewardsBurnTax = _rewardsBurnTax;
    }

    function setVaultTax(uint256 _rewardsVaultTax) public {
        rewardsVaultTax = _rewardsVaultTax;
    }

    
    function setLockTime(uint256 _lockTime) external onlyOwner {
        LOCK_TIME = _lockTime;
    }


function calculateRewards(address _staker)
    internal
    view
    returns (uint256 _rewards)
{
    uint256 timeSinceLastUpdate = block.timestamp - stakers[_staker].timeOfLastUpdate;
    uint256 rewardsRate = rewardsPerHour / 2592000;
    
    // Loop through each staked token and calculate rewards
    for (uint256 i = 0; i < stakers[_staker].stakedTokens.length; i++) {
        uint256 stakedAmount = 1; // assume each staked token has a staked amount of 1
        _rewards += timeSinceLastUpdate * stakedAmount * rewardsRate;
    }
}

        function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    event RewardsClaimed(address indexed staker, uint256 amount);
}