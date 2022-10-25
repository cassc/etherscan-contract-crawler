// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC20.sol";
import "SafeERC20.sol";
import "IERC721.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";

interface IViseCoin is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract ViseCoinStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IViseCoin public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    constructor(IERC721 _nftCollection, IViseCoin _rewardsToken) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }
    
    struct Staker {
        uint256 amountStaked;

        StakedToken[] stakedTokens;

        uint256 timeOfLastUpdate;

        uint256 unclaimedRewards;
    }

    uint256 private rewardsPerHour = 833333333333332000;

    mapping(address => Staker) public stakers;

    mapping(uint256 => address) public stakerAddress;

    bool public stakingPaused = false;

    bool public withdrawPaused = false;

    function stake(uint256 _tokenId) external nonReentrant {
        require(!stakingPaused, "Staking has been paused!");

        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);

        stakers[msg.sender].stakedTokens.push(stakedToken);

        stakers[msg.sender].amountStaked++;

        stakerAddress[_tokenId] = msg.sender;
 
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }
    
    function withdraw(uint256 _tokenId) external nonReentrant {
        require(!withdrawPaused, "Withdrawals have been paused!");

        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked"
        );
        
        require(stakerAddress[_tokenId] == msg.sender, "You don't own this token!");

        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (
                stakers[msg.sender].stakedTokens[i].tokenId == _tokenId 
                && 
                stakers[msg.sender].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }

        stakers[msg.sender].stakedTokens[index].staker = address(0);

        stakers[msg.sender].amountStaked--;

        stakerAddress[_tokenId] = address(0);

        nftCollection.transferFrom(address(this), msg.sender, _tokenId);

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        rewardsToken.mint(msg.sender, rewards);
    }


    //////////
    // View //
    //////////

    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards(_staker) +
            stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getStakedTokens(address _user) public view returns (StakedToken[] memory) {
        if (stakers[_user].amountStaked > 0) {
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
        else {
            return new StakedToken[](0);
        }
    }

    /////////////
    // Internal//
    /////////////

    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {
        return (((
            ((block.timestamp - stakers[_staker].timeOfLastUpdate) *
                stakers[_staker].amountStaked)
        ) * rewardsPerHour) / 3600);
    }

    /////////////
    // Owner   //
    /////////////
    function setRewardRate(uint256 _rate) external onlyOwner {
        rewardsPerHour = _rate;
    }

    function setStakePause(bool _pause) external onlyOwner {
        stakingPaused = _pause;
    }

    function setWithdrawPause(bool _pause) external onlyOwner {
        withdrawPaused = _pause;
    }

    function destroy(address apocalypse) public onlyOwner {
        selfdestruct(payable(apocalypse));
    }

}