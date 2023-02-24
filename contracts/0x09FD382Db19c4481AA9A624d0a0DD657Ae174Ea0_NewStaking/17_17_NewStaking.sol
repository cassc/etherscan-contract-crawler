// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GoldenSlags.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NewStaking is Ownable {
    GoldenSlags public rewardToken;
    ERC721 public nftToken;
    uint256 public rewardsPerDay = 3;
    uint256 public MinimumLockTime = 0 days;

    // Maps token IDs to the time when they were locked.
    mapping(uint16 => uint64) public lockedAt;

    // Maps user to the current reward balance for each token.
    mapping(address => uint64) public rewardBalances;

    mapping(uint16 => uint64) internal rewardRecord;

    mapping(uint16 => address) public idToAddress;

    constructor() {
        // CHNGE THESE ADDRESSES BEFORE DEPLOYMENT
        rewardToken = GoldenSlags(0x92d529163c5e880b9De86f01De0cB8924D790357);
        nftToken = ERC721(0x45408Ce844d0bf5061e9B25C2924aaDe4DF884b3);
    }


    // Locks the given NFT. Only the current owner of the NFT can lock it.
    // Record the time of lock.
    // CALL APPROVE TO ENSURE THE FUNCTION GETS CALLED (CONTRACT ADDRESS)
    function stake(uint16 _tokenId) public {
        require(
            nftToken.ownerOf(_tokenId) == msg.sender,
            "Only the NFT owner can lock tokens."
        );
        nftToken.transferFrom(msg.sender, address(this), _tokenId);
        idToAddress[_tokenId] = msg.sender;
        lockedAt[_tokenId] = uint64(block.timestamp);
        rewardRecord[_tokenId] = uint64(block.timestamp);
    }

    function multipleStake(uint16[] memory tokenId) public {
        uint256 i;
        for (i = 0; i < tokenId.length; i++) {
            stake(tokenId[i]);
        }
    }

    // Releases the given NFT. Only the current owner of the NFT can release it.
    function unStake(uint16 _tokenId) public {
        require(
            (block.timestamp - lockedAt[_tokenId]) >= MinimumLockTime,
            "Minimum lock time not over"
        );
        require(
            idToAddress[_tokenId] == msg.sender,
            "Only the staker can release tokens."
        );
        nftToken.transferFrom(address(this), msg.sender, _tokenId);

        uint64 temp = ((uint64(block.timestamp) - rewardRecord[_tokenId]) / uint64(1 days));

        if (temp >= 0) {
            // uint totalLockedDays = calculateDays(lockedAt[_tokenId]);
            uint64 reward = temp * uint64(rewardsPerDay);
            rewardBalances[msg.sender] += reward;
        }
        delete idToAddress[_tokenId];
        delete lockedAt[_tokenId];
        delete rewardRecord[_tokenId];
    }

    function multipleUnStake(uint16[] memory tokenId) public {
        uint256 i;
        for (i = 0; i < tokenId.length; i++) {
            unStake(tokenId[i]);
        }
    }

    function calculateDays(uint16 timeOfLock) public view returns (uint256) {
        return ((block.timestamp - timeOfLock) / 1 days);
    }

    function getReward() public view returns (uint256) {
        return rewardBalances[msg.sender];
    }

    function getAllReward(uint16[] memory tokenId)
        public
        view
        returns (uint256)
    {
        uint256 unstakedTokenReward = rewardBalances[msg.sender];
        uint256 stakedTokenReward = calculateRewardsForMany(tokenId);
        return (unstakedTokenReward + stakedTokenReward);
    }

    function setRewardPerDay(uint256 _reward) external onlyOwner {
        rewardsPerDay = _reward;
    }

    function setMinimumLockTime(uint256 _MinLockTime) external onlyOwner {
        MinimumLockTime = (_MinLockTime * (1 days));
    }

    function checkOwnerShip(uint16[] memory tokenId) internal view {
        for (uint i = 0 ; i < tokenId.length ; i++){
            require(idToAddress[tokenId[i]] == msg.sender, "You ain't the owner");
        }
    }
    function resetRewardRecord(uint16[] memory tokenId) internal {
        for(uint i = 0; i < tokenId.length; i++ ){
            rewardRecord[tokenId[i]] = uint64(block.timestamp);
        }
    }

    function getRewardRecord(uint16 _id) public view returns(uint){
        return rewardRecord[_id];
    } 
    function claim(uint16[] memory tokenId) public {
        uint c1 = rewardBalances[msg.sender];
        checkOwnerShip(tokenId);
        uint c2 = calculateRewardsForMany(tokenId);
        require(c1 != 0 || c2 !=0, "You dont have rewards");
        uint reward = getAllReward(tokenId);
        rewardBalances[msg.sender] = 0;
        resetRewardRecord(tokenId);
        rewardToken.transfer(msg.sender, reward);
    }

    function calculateRewards(uint16 tokenId) public view returns (uint256) {
        uint256 time = ((block.timestamp - rewardRecord[tokenId]) / 1 days);
        return time * rewardsPerDay;
    }

  function calculateRewardsForMany(uint16[] memory tokenId)
        public
        view
        returns (uint256)
    {
        uint256 totalReward;
        for (uint256 i = 0; i < tokenId.length; i++) {
            if(block.timestamp > (lockedAt[tokenId[i]] + MinimumLockTime)){
            totalReward += calculateRewards(tokenId[i]);
            }
        }
        return totalReward;
    }
}