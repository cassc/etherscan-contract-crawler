// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StakingMunieV2 is Ownable, ERC721Holder, ReentrancyGuard, Pausable {
    IERC721 private stakingToken; // Munie NFT
    IERC20 private rewardToken; // HANePlatform token

    constructor(address _stakingToken, address _rewardToken) onlyOwner {
        stakingToken = IERC721(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    struct Staker {
        uint256[] tokenIds; // Stacked NFT tokenID
        uint256 totalReward; // The total amount of HAN Token received as reward
        uint256 unclaimedRewards; // The accumulated amount of HAN token before "CLAIM"
        uint256 countStaked; // The amount of NFT tokenID staked
        uint256 timeOfLastUpdate; // Last updated time by NFT tokenID
    }

    uint256 public constant rewardTokenPerStakingToken = 1157407407407; // Quantity of HAN tokens rewarded per NFT tokenID
   
    uint256[] private totalTokenIds;

    mapping(uint256 => address) public tokenOwner; // Return owner address when NFT tokenID is entered
    mapping(address => Staker) private stakers;

    // ------------------ View Functions ------------------ //

    function getStakerData(address _user) public view returns (Staker memory) {
        return stakers[_user];
    }

    function getTotalTokenIds() public view returns (uint256[] memory) {
        return totalTokenIds;
    }

    // ------------------ Transaction Functions ------------------ //

    // "STAKE" function
    function stake(uint256 _tokenId) public nonReentrant whenNotPaused {
        require(stakingToken.ownerOf(_tokenId) == msg.sender, "user must be the owner of the token");
        require(rewardToken.balanceOf(address(this)) - 365 days * (totalTokenIds.length * rewardTokenPerStakingToken) > 365 days * rewardTokenPerStakingToken, "Total amount of rewards is too high");
        Staker storage staker = stakers[msg.sender];
        if (staker.countStaked == 0) {
            _stake(_tokenId);
        } else {
            staker.unclaimedRewards += calculateRewards(msg.sender);
            _stake(_tokenId);
        }
    }

    function _stake(uint256 _tokenId) internal {
        Staker storage staker = stakers[msg.sender];
        staker.timeOfLastUpdate = block.timestamp;
        tokenOwner[_tokenId] = msg.sender;
        staker.countStaked += 1;
        totalTokenIds.push(_tokenId);
        staker.tokenIds.push(_tokenId);
        stakingToken.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Staked(msg.sender, _tokenId);
    }

    // "UNSTAKE" function
    function unStake(uint256 _tokenId) public nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(tokenOwner[_tokenId] == msg.sender, "user must be the owner of the token");
        staker.unclaimedRewards += calculateRewards(msg.sender);
        staker.timeOfLastUpdate = block.timestamp;
        tokenOwner[_tokenId] = address(0);
        staker.countStaked--;
        removeByValue(_tokenId, staker.tokenIds);
        removeByValue(_tokenId, totalTokenIds);
        stakingToken.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit Unstaked(msg.sender, _tokenId);
    }

// "CLAIM" function
    function claimReward() public nonReentrant {
        Staker storage staker = stakers[msg.sender];
        uint256 rewards = calculateRewards(msg.sender) + staker.unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        require(rewards < rewardToken.balanceOf(address(this)), "Not enough tokens");
        staker.totalReward += rewards;
        staker.timeOfLastUpdate = block.timestamp;
        staker.unclaimedRewards = 0;
        rewardToken.transfer(msg.sender, rewards);
        emit RewardPaid(msg.sender, rewards);
    }

    // ------------------ Admin ------------------ //

    // Pause Staking
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    function recoverERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit RecoveredERC721(_tokenAddress, _tokenId);
    }

    // ------------------ Private Functions ------------------ //

    // Reward amount check function
    function calculateRewards(address _user) private view returns (uint256) {
        Staker storage staker = stakers[_user];
        uint256 reward;
        uint256 stakedTime = block.timestamp - staker.timeOfLastUpdate;
        reward = stakedTime * (staker.countStaked * rewardTokenPerStakingToken);
        return reward;
    }

    function find(uint256 value, uint256[] storage tokenIds) private view returns (uint256) {
        uint256 i = 0;
        while (tokenIds[i] != value) {
            i++;
        }
        return i;
    }

    function removeByValue(uint256 value, uint256[] storage tokenIds) private {
        uint256 i = find(value, tokenIds);
        removeByIndex(i, tokenIds);
    }

    function removeByIndex(uint256 i, uint256[] storage tokenIds) private {
        while (i < tokenIds.length - 1) {
            tokenIds[i] = tokenIds[i + 1];
            i++;
        }
        tokenIds.pop();
    }

    // ------------------ Event ------------------ //

    event Unstaked(address owner, uint256 tokenId);
    event Staked(address owner, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);
    event RecoveredERC20(address token, uint256 amount);
    event RecoveredERC721(address token, uint256 tokenId);
}