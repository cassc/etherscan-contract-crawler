// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./BeachHutMembershipI.sol";

//     __    __  ______  __      __  ______  __  __      
//    /\ "-./  \/\  __ \/\ \    /\ \/\  == \/\ \/\ \     
//    \ \ \-./\ \ \  __ \ \ \___\ \ \ \  __<\ \ \_\ \    
//     \ \_\ \ \_\ \_\ \_\ \_____\ \_\ \_____\ \_____\   
//      \/_/  \/_/\/_/\/_/\/_____/\/_/\/_____/\/_____/   
//     ______  ______  __  __   __                       
//    /\  ___\/\  __ \/\ \/\ "-.\ \                      
//    \ \ \___\ \ \/\ \ \ \ \ \-.  \                     
//     \ \_____\ \_____\ \_\ \_\\"\_\                    
//      \/_____/\/_____/\/_/\/_/ \/_/                    
                                       
contract MalibuCoin is ERC20, ERC20Permit, Ownable, ReentrancyGuard {

    uint256 public constant maxSupply = 1000000 * 10 ** 18; //(* 10 ** 18)
    uint32 public rewardsPerRound = 10;
    uint32 public genesisRewardsPerRound = 10;
    uint256 public epochLength;
    uint32 public genesisTokenId = 1;

    BeachHutMembershipI public membership;

    constructor() ERC20("Malibu Coin", "KMC") ERC20Permit("Malibu Coin") {
        epochLength = 86400; // seconds
        _mint(msg.sender, 100000 * 10 ** 18);
    }

    function claimMalibuCoins() 
        public 
        nonReentrant 
    {
        require(maxSupply > totalSupply(), "All tokens issued");
        _mint(msg.sender, getUnclaimedMalibuCoins(msg.sender));
        membership.setLastRewarded(msg.sender);

        if (membership.getRetroActiveRewards(msg.sender) > 0) {
            membership.resetRetroActiveRewards(msg.sender);
        }
    }

    //=============================================================================
    // Coin Calculation Functions
    //=============================================================================

    function getUnclaimedMalibuCoins(address account) public view returns (uint256 calculatedAmount) {
        uint256 membershipTokenId = 0;
        uint256 membershipTokenCount = 0;
        bool isOwner = false;
        bool isGenesisOwner = false;

        do {
            membershipTokenId++;
            if (membership.balanceOf(account, membershipTokenId) >= 1) {
                if (!isGenesisOwner) {
                    isGenesisOwner = membershipTokenId == genesisTokenId ? true : false;
                }
                isOwner = true;
                membershipTokenCount += membership.balanceOf(account, membershipTokenId);
            }
        } while (membership.exists(membershipTokenId));

        require(isOwner, "You need a membership token to claim");

        uint256 extras;
        uint256 epochsToReward;
        uint256 lastReward = membership.getLastRewarded(account);
        uint256 rewards = rewardsPerRound;

        epochsToReward = (block.timestamp - lastReward) / epochLength;

        if (isGenesisOwner) {
            rewards += genesisRewardsPerRound;
        } 

        if (membership.getRetroActiveRewards(msg.sender) > 0) {
            extras = membership.getRetroActiveRewards(msg.sender);
        }

        calculatedAmount += (((rewards * epochsToReward) * membershipTokenCount) + extras);
        calculatedAmount = mintMaxSupply((calculatedAmount * 10 ** 18));
    }
    
    function mintMaxSupply(uint256 amount) private view returns (uint256) { 
        if (totalSupply() + amount > maxSupply) {
            amount = (maxSupply - totalSupply());
        }

        return amount;
     }

    function remainingSupply() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    //=============================================================================
    // Admin Functions
    //=============================================================================

    function setRewardsPerRound(uint32 qty) public onlyOwner {
        rewardsPerRound = qty;
    }

    function setGenesisRewardsPerRound(uint32 qty) public onlyOwner {
        genesisRewardsPerRound = qty;
    }

    function setEpochLength(uint256 epoch) public onlyOwner {
        epochLength = epoch;
    }

    function setGenesisTokenId(uint32 id) public onlyOwner {
        genesisTokenId = id;
    }

    function setBeachHutMembership(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        membership = BeachHutMembershipI(_contract);
    }
}