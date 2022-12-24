// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRewardToken {
  function mint(address to, uint256 amount) external;
}

contract DwellerStaking is Ownable {

    IRewardToken public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }

    struct Stake {
        uint256 amountStaked;
        StakedToken[] stakedTokens;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    uint256 public rewardsPerDay = 10 ether;

    mapping (address => Stake) public userStake;
    mapping (uint256 => address) public tokenOwners;

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    constructor(IERC721 _nftCollection, IRewardToken _rewardsToken) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
    }

    function stake(uint256 _tokenId) external {
        _stake(msg.sender, _tokenId);
    }

    function batchStake(uint256[] memory _tokenIds) external {
        for(uint256 i = 0; i <_tokenIds.length; i++){
            _stake(msg.sender, _tokenIds[i]);
        }
    }

    function _stake(address _user, uint256 _id) internal  {
        require(nftCollection.ownerOf(_id) == _user, "not your token");

        if (userStake[_user].amountStaked > 0) {
            uint256 rewards = calculateRewards(_user);
            userStake[_user].unclaimedRewards += rewards;
        }

        nftCollection.transferFrom(_user, address(this), _id);

        tokenOwners[_id] = _user;
        userStake[_user].stakedTokens.push(
            StakedToken(_user, _id)
        );
        userStake[_user].timeOfLastUpdate = block.timestamp;
        userStake[_user].amountStaked++;

        emit NFTStaked(_user, _id, block.timestamp);
    }

    function unstake(uint256 _tokenId) external {
        _unstake(msg.sender, _tokenId);
    }

    function batchUnstake(uint256[] memory _tokenIds) external {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            _unstake(msg.sender, _tokenIds[i]);
        }
    }

    function _unstake(address _user, uint256 _id) internal {
        require(
            userStake[_user].amountStaked > 0,
            "You have no tokens staked"
        );
        require(tokenOwners[_id] == _user, "You don't own this token");
        StakedToken[] storage stakes = userStake[_user].stakedTokens;

        uint256 rewards = calculateRewards(_user);
        userStake[_user].unclaimedRewards += rewards;

        uint256 index = 0;
        for(uint256 i = 0; i < stakes.length; i++){
            if(stakes[i].tokenId == _id && stakes[i].staker != address(0)){
                index = i;
                break;
            }
        }

        delete tokenOwners[_id];
        stakes[index] = stakes[stakes.length - 1];
        stakes.pop();
        userStake[_user].amountStaked--;
        userStake[_user].timeOfLastUpdate = block.timestamp;

        nftCollection.transferFrom(address(this), _user, _id);
        emit NFTUnstaked(_user, _id, block.timestamp);
    }

    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) + userStake[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");

        userStake[msg.sender].unclaimedRewards = 0;
        userStake[msg.sender].timeOfLastUpdate = block.timestamp;

        rewardsToken.mint(msg.sender, rewards);
        emit Claimed(msg.sender, rewards);
    }

    function balanceOf(address _user) external view returns(uint256){
        return userStake[_user].amountStaked;
    }

    function tokenOfOwnerStaked(address _user) external view returns(StakedToken[] memory){
        StakedToken[] memory tmp = new StakedToken[](userStake[_user].amountStaked);
        uint256 index = 0;
        for(uint256 i = 0; i < userStake[_user].stakedTokens.length; i++) {
            tmp[index] = userStake[_user].stakedTokens[i];
            index++;
        }
        return tmp;
    }

    function earnings(address _user) external view returns(uint256){
        uint256 rewards = calculateRewards(_user) + userStake[_user].unclaimedRewards;
        return rewards;
    }

    function calculateRewards(address _user) internal view returns(uint256) {
        Stake memory staker = userStake[_user];
        return (((
            ((block.timestamp - staker.timeOfLastUpdate) * staker.amountStaked)
        ) * rewardsPerDay) / 86400);
    }
}