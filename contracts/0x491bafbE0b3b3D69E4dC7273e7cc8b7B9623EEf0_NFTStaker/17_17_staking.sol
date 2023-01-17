// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GoldenSlags.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStaker is Ownable {

    GoldenSlags public rewardToken;
    ERC721 public nftToken;
    uint public rewardsPerDay = 3;
    uint public MinimumLockTime = 0 days;

    // Maps token IDs to the time when they were locked.
    mapping(uint256 => uint256) public lockedAt;

    // Maps user to the current reward balance for each token.
    mapping(address => uint256) public rewardBalances;


    mapping(uint256 => address) public idToAddress;

    constructor() {
        // CHNGE THESE ADDRESSES BEFORE DEPLOYMENT
        rewardToken = GoldenSlags(0x92d529163c5e880b9De86f01De0cB8924D790357);
        nftToken = ERC721(0x45408Ce844d0bf5061e9B25C2924aaDe4DF884b3);
    }

    // Locks the given NFT. Only the current owner of the NFT can lock it.
    // Record the time of lock.
    // CALL APPROVE TO ENSURE THE FUNCTION GETS CALLED (CONTRACT ADDRESS)
    function stake(uint256 _tokenId) public {
        require(
            nftToken.ownerOf(_tokenId) == msg.sender,
            "Only the NFT owner can lock tokens."
        );
        nftToken.transferFrom(msg.sender, address(this), _tokenId);
        idToAddress[_tokenId] = msg.sender;
        lockedAt[_tokenId] = block.timestamp;
    }

    function multipleStake(uint[] memory tokenId) public {
        uint i;
        for(i = 0; i < tokenId.length; i++){
        stake(tokenId[i]);
        }
    }
    // Releases the given NFT. Only the current owner of the NFT can release it.
    function unStake(uint256 _tokenId) public {
        require((block.timestamp - lockedAt[_tokenId]) >=  MinimumLockTime,"Minimum lock time not over");
        require(
            idToAddress[_tokenId] == msg.sender,
            "Only the staker can release tokens."
        );
        nftToken.transferFrom(address(this), msg.sender, _tokenId);

        if( block.timestamp >= (lockedAt[_tokenId] + 1 days) ) {
            uint totalLockedDays = calculateDays(lockedAt[_tokenId]);
            uint reward = totalLockedDays * rewardsPerDay;
            rewardBalances[msg.sender] += reward;
        }
        delete idToAddress[_tokenId];
        delete lockedAt[_tokenId];
    }

    function multipleUnStake(uint[] memory tokenId) public {
        uint i;
        for(i = 0; i < tokenId.length; i++){
        unStake(tokenId[i]);
        }
    }

    function calculateDays(uint timeOfLock) public view returns(uint){
        return ((block.timestamp - timeOfLock)/1 days);
    }

    function getReward() public view returns(uint){
        return rewardBalances[msg.sender];
    }

    function setRewardPerDay(uint _reward) external onlyOwner {
        rewardsPerDay = _reward;
    }

    function setMinimumLockTime(uint _MinLockTime) external onlyOwner {
        MinimumLockTime = (_MinLockTime * (1 days));
    }

    // Claims the reward for the given NFT. Only the current owner of the NFT can claim the reward.
    function claim() public {
        require(rewardBalances[msg.sender] != 0,"You Don't have any rewards.");
        uint reward = rewardBalances[msg.sender];
        rewardBalances[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);

    }

    function calculateRewards(uint tokenId) public view returns(uint){
        uint time = ((block.timestamp - lockedAt[tokenId])/ 1 days);
        return time * rewardsPerDay;
    }

    function calculateRewardsForMany(uint[] memory tokenId) public view returns(uint){
        uint totalReward;
        for(uint i = 0; i < tokenId.length; i++){
            totalReward += calculateRewards(tokenId[i]);
        }
        return totalReward;
    }
}