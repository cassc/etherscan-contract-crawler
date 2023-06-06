// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';

/*
* @title Staking for Pixelvault ERC721 tokens
*
* @author Niftydude
*/
contract ComicStaking is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet; 

    IERC20 public immutable rewardToken;
    IERC721 public immutable stakedTokenContract;

    uint256 constant MAX_REWARD_CHANGES = 2000;

    uint128 public rewardPerBlock;
    uint128 public lockupPeriod = 2592000; // 30 days

    struct Stake {
        uint128 lockupExpires;
        uint128 lastClaimedBlock;
    }

    struct RewardChanged {
        uint128 block;
        uint128 rewardPerBlock;
    }

    RewardChanged[] rewardChanges; 

    event Staked(address indexed account, uint256[] tokenIds);
    event Unstaked(address indexed account, uint256[] tokenIds);
    event RewardsClaimed(address indexed account, uint256 amount);
    event RewardsChanged(uint128 indexed rewardPerBlock);
    event LockupPeriodChanged(uint128 indexed lockupPeriod);

    mapping(uint256 => Stake) public stakes;
    mapping(address => EnumerableSet.UintSet) private stakedTokens;

    constructor(address _rewardTokenContract, address _stakedTokenContract, uint128 _rewardPerBlock)  {
        rewardToken = IERC20(_rewardTokenContract);        
        stakedTokenContract = IERC721(_stakedTokenContract);

        rewardPerBlock = _rewardPerBlock;     
        rewardChanges.push(RewardChanged(uint128(block.number), _rewardPerBlock));           
    }

    /**
    * @notice pause staking, unstaking and claiming rewards
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @notice unpause staking, unstaking and claiming rewards
    */
    function unpause() external onlyOwner {
        _unpause();
    }       

    /**
    * @notice set ERC20 reward amount per block
    * 
    * @param _rewardPerBlock the reward amount
    */
    function setRewardsPerBlock(uint128 _rewardPerBlock) external onlyOwner {
        require(rewardChanges.length < MAX_REWARD_CHANGES, "Set rewards: Max reward changes reached");

        rewardPerBlock = _rewardPerBlock;
        rewardChanges.push(RewardChanged(uint128(block.number), _rewardPerBlock));

        emit RewardsChanged(_rewardPerBlock);
    }

    /**
    * @notice set lockup period in seconds. 
    * unstaking or claiming rewards not allowed until lockup period expired
    * 
    * @param _lockupPeriod length of the lockup period in seconds
    */
    function setLockupPeriod(uint128 _lockupPeriod) external onlyOwner {
        lockupPeriod = _lockupPeriod;

        emit LockupPeriodChanged(_lockupPeriod);
    }    

    /**
    * @notice withdraw reward tokens owned by staking contract
    * 
    * @param to the token ids to unstake
    * @param amount the amount of tokens to withdraw
    */
    function withdraw(address to, uint256 amount) external onlyOwner {
        require(
            rewardToken.balanceOf(address(this)) >= amount, 
            "Withdraw: balance exceeded");

        rewardToken.transfer(to, amount);
    }

    /**
    * @notice stake given token ids for specified user
    * 
    * @param tokenIds the token ids to stake
    */
    function stake(uint256[] calldata tokenIds) external whenNotPaused nonReentrant {
        require(tokenIds.length <= 40 && tokenIds.length > 0, "Stake: amount prohibited");

        for (uint256 i; i < tokenIds.length; i++) {
            require(stakedTokenContract.ownerOf(tokenIds[i]) == msg.sender, "Stake: sender not owner");

            stakedTokenContract.safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            stakes[tokenIds[i]] = Stake(uint128(block.timestamp + lockupPeriod), uint128(block.number));
            stakedTokens[msg.sender].add(tokenIds[i]);
        }        

        emit Staked(msg.sender, tokenIds);
    }    

    /**
    * @notice unstake given token ids and claim rewards
    * 
    * @param tokenIds the token ids to unstake
    */
    function unstake(uint256[] calldata tokenIds) external whenNotPaused nonReentrant {
        require(tokenIds.length <= 40 && tokenIds.length > 0, "Unstake: amount prohibited");

        uint256 rewards;

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                stakedTokens[msg.sender].contains(tokenIds[i]), 
                "Unstake: token not staked"
            );
            require(
                stakes[tokenIds[i]].lockupExpires < block.timestamp, 
                "Unstake: lockup period not expired"
            );
            
            rewards += calculateRewards(tokenIds[i]);

            stakedTokens[msg.sender].remove(tokenIds[i]);
            delete stakes[tokenIds[i]];
           
            stakedTokenContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
        rewardToken.transfer(msg.sender, rewards);

        emit Unstaked(msg.sender, tokenIds);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
    * @notice unstake given token ids and forfeit rewards
    * 
    * @param tokenIds the token ids to unstake
    */
    function exitWithoutRewards(uint256[] calldata tokenIds) external whenNotPaused nonReentrant {
        require(tokenIds.length <= 40 && tokenIds.length > 0, "Unstake: amount prohibited");

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                stakedTokens[msg.sender].contains(tokenIds[i]), 
                "Unstake: token not staked"
            );
            
            stakedTokens[msg.sender].remove(tokenIds[i]);
            delete stakes[tokenIds[i]];
           
            stakedTokenContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }

        emit Unstaked(msg.sender, tokenIds);
    }    

    /**
    * @notice claim rewards for given token ids
    * 
    * @param tokenIds the token ids to claim for
    */
    function claimRewards(uint256[] calldata tokenIds) external whenNotPaused {
        require(tokenIds.length > 0, "ClaimRewards: missing token ids");

        uint256 rewards;

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                stakedTokens[msg.sender].contains(tokenIds[i]), 
                "ClaimRewards: token not staked"
            );
            require(
                stakes[tokenIds[i]].lockupExpires < block.timestamp, 
                "ClaimRewards: lockup period not expired"
            );            
            
            rewards += calculateRewards(tokenIds[i]);
            stakes[tokenIds[i]].lastClaimedBlock = uint128(block.number);
        }

        rewardToken.transfer(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }      

    /**
    * @notice calculate rewards for all staken token ids of a given account
    * 
    * @param account the account to calculate for
    */
    function calculateRewardsByAccount(address account) external view returns (uint256) {
        uint256 rewards;

        for (uint256 i; i < stakedTokens[account].length(); i++) {
            rewards += calculateRewards(stakedTokens[account].at(i));
        }

        return rewards;
    }    

    /**
    * @notice calculate rewards for given token id
    * 
    * @param tokenID the token id to calculate for
    */
    function calculateRewards(uint256 tokenID) public view returns (uint256) {
        require(stakes[tokenID].lastClaimedBlock != 0, "token not staked");

        uint256 rewards;
        uint256 blocksPassed;

        uint128 lastClaimedBlock = stakes[tokenID].lastClaimedBlock;

        uint256 from;
        uint256 last;

        for(uint256 i=0; i < rewardChanges.length; i++) {
            bool hasNext = i+1 < rewardChanges.length;

            from = rewardChanges[i].block >= lastClaimedBlock ? 
                   rewardChanges[i].block : 
                   lastClaimedBlock;
            
            last = hasNext ? 
                   (rewardChanges[i+1].block >= lastClaimedBlock ? 
                      rewardChanges[i+1].block : 
                      from 
                   ) : 
                   block.number;

            blocksPassed = last - from;
            rewards += rewardChanges[i].rewardPerBlock * blocksPassed;         
        }
        return rewards;
    }      

    /**
    * @notice return all staked token ids for a given account
    * 
    * @param account the account to return token ids for
    */
    function stakedTokensOf(address account) external view returns (uint256[] memory) {
      uint256[] memory tokenIds = new uint256[](stakedTokens[account].length());

      for (uint256 i; i < tokenIds.length; i++) {
        tokenIds[i] = stakedTokens[account].at(i);
      }

      return tokenIds;
    }    

    function onERC721Received(address operator, address, uint256, bytes memory) public view override returns (bytes4) {
        require(operator == address(this), "Operator not staking contract");

        return this.onERC721Received.selector;
    }
}