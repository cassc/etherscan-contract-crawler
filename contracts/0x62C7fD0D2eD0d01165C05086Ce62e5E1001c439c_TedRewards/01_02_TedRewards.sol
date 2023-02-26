// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface INFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract TedRewards {
    using SafeMath for uint256;

    mapping(uint256 => uint256) private lastClaimedTime;
    mapping(uint256 => uint256) private accumulatedRewards;
    mapping(uint256 => bool) private firstClaim;
    address private tokenAddress = 0x6ca0269dca415313256cfecD818F32c5AfF0A518; // ERC20 token address
    uint256 private rewardRate = 50; // 50 tokens per day
    uint256 private startingBalance = 1000; // 1000 tokens starting balance for each NFT
    address private nftAddress = 0x06BDC702fb8af5Af8067534546e0C54ea4243Ea9; // NFT token address

    function claimRewards(uint256[] calldata tokenIds) external {
        address owner = msg.sender;
        uint256 totalReward = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(INFT(nftAddress).ownerOf(tokenIds[i]) == owner, "Only NFT owner can claim reward");
            uint256 reward = calculateReward(tokenIds[i]);
            require(reward > 0, "No reward available to claim");
            accumulatedRewards[tokenIds[i]] = accumulatedRewards[tokenIds[i]].add(reward);
            lastClaimedTime[tokenIds[i]] = block.timestamp;
            if (firstClaim[tokenIds[i]]) {
                accumulatedRewards[tokenIds[i]] = accumulatedRewards[tokenIds[i]].add(startingBalance);
                firstClaim[tokenIds[i]] = false;
            }
            totalReward = totalReward.add(reward);
        }
        require(IERC20(tokenAddress).transfer(owner, totalReward * 10**18), "Reward transfer failed");
    }

    function calculateReward(uint256 tokenId) public view returns (uint256) {
        uint256 timeSinceLastClaim = block.timestamp - lastClaimedTime[tokenId];
        if (lastClaimedTime[tokenId] == 0) {
            return startingBalance;
        }
        uint256 reward = rewardRate.mul(timeSinceLastClaim).div(1 days);
        return reward;
    }

    function getAccumulatedRewards(uint256 tokenId) public view returns (uint256) {
        return accumulatedRewards[tokenId];
    }

    function getContractBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}