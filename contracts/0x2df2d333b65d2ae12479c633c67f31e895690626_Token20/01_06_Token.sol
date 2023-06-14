// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface INftV1 {
    /**
     * Get conditionId by tokenId
     */
     function getConditionIdByTokenId(uint256 tokenId) external view returns (uint256);
    /**
     * Burn token by id
     */
    function burnCaps(address owner, uint256 tokenId)
        external;
    /**
     * Check if sender is onwer of Nft by tokenId
     */    
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Token20 is ERC20("CAPS","CAPS"), Ownable {
    mapping(uint256 => address) public collectionsAddresses;
    mapping(uint256 => uint256) public dropChance;
    uint256 percent = 90909;
    uint256 public maxSupply = 5250000 * 10 ** 18; //total supply in wei

    constructor() {
        dropChance[1] = 25;
        dropChance[2] = 100;    
        dropChance[3] = 275; 
        dropChance[4] = 1600; 
        dropChance[5] = 8000; 
    }

    function addCollection(address collectionAddress, uint256 index ) public onlyOwner {
        collectionsAddresses[index] =  collectionAddress;
    }

    function getIncrement(uint256 id) public pure returns (uint256) {
        uint256 increment = 0;
        uint256 collection = 1;
        while (id >= collection + 11 && id != 11220) {
            collection += 11;
        }
        increment = id - collection;
        if (increment < 0) {
            increment = 0;
        } else if (increment >= 11) {
            increment = 10;
        }
        return increment + 1;
    }

    function CalculateNftInToken(uint256 tokenId, uint256 conditionId) public view returns (uint256){
        uint256 collectionIndex = getCollectionByTokenId(tokenId);
        uint256 rarityIndex = getRarityByConditionId(conditionId, collectionIndex);
        uint256 conditionIdIndex = getIncrement(conditionId);
        uint256 award = (((((5250000 / (2 ** collectionIndex)) / 5 )) * (10 ** 13)) / (dropChance[rarityIndex])/100*(conditionIdIndex * percent));
        return award;
    }


    function burnNftGetToken(uint256[] memory tokenIds) public returns (uint256[] memory){
        require(tokenIds.length <= 19, "20 caps max");
        uint256[] memory rewards = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 collectionIndex = getCollectionByTokenId(tokenIds[i]);
            INftV1 instance = INftV1(collectionsAddresses[collectionIndex]);
            require(msg.sender == instance.ownerOf(tokenIds[i]), "You are not an owner");
            uint256 conditionId = instance.getConditionIdByTokenId(tokenIds[i]);
            uint256 reward = CalculateNftInToken(tokenIds[i], conditionId);
            require(maxSupply > totalSupply() + reward, "There are not enough tokens");
            _mint(msg.sender, reward);
            instance.burnCaps(msg.sender, tokenIds[i]);
            rewards[i] = reward;
        }
        return rewards;
    }

    function getCollectionByTokenId(uint256 id) public pure returns (uint256) {
        if (id >= 1 && id <= 3400000) {
            return (id - 1) / 100000 + 1;
        } else {
            return 0;
        }
    }

    function getRarityByConditionId(uint256 conditionId, uint256 collectionIndex) public pure returns (uint256) {
        uint256 adjustedConditionId = conditionId - ((collectionIndex - 1) * 330);
        if (adjustedConditionId >= 1  && adjustedConditionId <= 11 ) {
            return 1;
        } else if (adjustedConditionId >= 12  && adjustedConditionId <= 33 ) {
            return 2;
        } else if (adjustedConditionId >= 34   && adjustedConditionId <= 66 ) {
            return 3;
        } else if (adjustedConditionId >= 67  && adjustedConditionId <= 121 ) {
            return 4;
        } else if (adjustedConditionId >= 122  && adjustedConditionId <= 330 ) {
            return 5;
        } else {
            // handle tokenId greater than 330
            revert("Invalid tokenId/collectionIndex");
        }
    }
}