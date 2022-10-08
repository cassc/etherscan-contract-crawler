// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import {KoboldHealthBooster}  from "../interfaces/IKoboldHealthBooster.sol";

///@author @0xSimon_

library LibKoboldHealthBoosters {
    //Storage
    bytes32 internal constant NAMESPACE = keccak256("titanforge.kobold.health.items");
    event KoboldHealthBoosterUsed(uint indexed koboldTokenId,uint indexed healthToGive,uint indexed quantityUsed);
    struct Storage{
        mapping(uint => KoboldHealthBooster) koboldHealthBoosters;
        mapping(address => mapping(uint => uint)) balanceOfKoboldHealthBoosters;
        mapping(address => bool) approvedKoboldHealthBoosterPurchaser;
        mapping(address => bool) approvedKoboldHealthBoosterSpender;
        uint koboldHealthBoosterIdTracker;
    }
    
    function getStorage() internal pure returns(Storage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function purchaseKoboldHealthBooster(address from,uint koboldHealthBoosterId,uint quantity) internal {
        Storage storage s = getStorage();
        KoboldHealthBooster memory booster = s.koboldHealthBoosters[koboldHealthBoosterId];
        require(booster.isAvailableForPurchase,"Not For Sale");
        // if(booster.quantitySold + quantity > booster.maxQuantity) revert ("Sold Out");
        // s.booster[koboldHealthBoosterId].quantitySold = booster.quantitySold + quantity;
        s.balanceOfKoboldHealthBoosters[from][koboldHealthBoosterId] += quantity;
    }
    function useKoboldHealthBooster(address from,uint koboldTokenId,uint koboldHealthBoosterId,uint quantity) internal {
        Storage storage s = getStorage();
        if(msg.sender != tx.origin) {
        require(s.approvedKoboldHealthBoosterSpender[msg.sender] , "Not Approved Spender");
        }
        if(quantity > s.balanceOfKoboldHealthBoosters[from][koboldHealthBoosterId]) revert ("Kobold healthBooster: Insufficient healthBooster Balance");
        s.balanceOfKoboldHealthBoosters[from][koboldHealthBoosterId] -= quantity;
        emit KoboldHealthBoosterUsed(koboldTokenId,s.koboldHealthBoosters[koboldHealthBoosterId].healthBoost,quantity);
    }
    function getKoboldHealthBooster(uint koboldHealthBoosterId) internal view returns(KoboldHealthBooster memory) {
        Storage storage s = getStorage();
        return s.koboldHealthBoosters[koboldHealthBoosterId];
    }
    function queryBatchKoboldHealthBoosters(uint[] calldata koboldHealthBoosterIds) internal view returns(KoboldHealthBooster[] memory) {
            uint len = koboldHealthBoosterIds.length;
            KoboldHealthBooster[]  memory KoboldHealthBoosters = new KoboldHealthBooster[](len);
            for(uint i; i < len;){
                uint id = koboldHealthBoosterIds[i];
                KoboldHealthBoosters[i] = getKoboldHealthBooster(id);
                 unchecked{++i;}
            }
            return KoboldHealthBoosters;
    }

    function queryUserBalanceBatchHealthBoosters(address account,uint[] calldata koboldHealthBoosterIds) internal view returns(uint[] memory) {
            uint len = koboldHealthBoosterIds.length;
            uint[]  memory koboldHealthBoosters = new uint[](len);
            for(uint i; i < len;){
                uint id = koboldHealthBoosterIds[i];
                koboldHealthBoosters[i] = getKoboldHealthBoosterBalance(account,id);
                 unchecked{++i;}
            }
            return koboldHealthBoosters;
    }

    function getKoboldHealthBoosterBalance(address user,uint koboldHealthBoosterId) internal view returns(uint) {
        Storage storage s = getStorage();
        return s.balanceOfKoboldHealthBoosters[user][koboldHealthBoosterId];
    }
    function approveKoboldHealthBoosterSpender(address spender) internal {
        Storage storage s = getStorage();
        s.approvedKoboldHealthBoosterSpender[spender] = true;
    }
    function unapproveKoboldHealthBoosterSpender(address spender) internal {
        Storage storage s = getStorage();
        delete s.approvedKoboldHealthBoosterSpender[spender];
    }
    function setKoboldHealthBooster(KoboldHealthBooster memory koboldHealthBooster) internal {
        Storage storage s = getStorage();
        s.koboldHealthBoosters[s.koboldHealthBoosterIdTracker] = koboldHealthBooster;
        ++s.koboldHealthBoosterIdTracker;
    }

    function overrideExistingHealthBooster(uint healthBoosterId,KoboldHealthBooster memory koboldHealthBooster) internal {
        Storage storage s = getStorage();
          s.koboldHealthBoosters[healthBoosterId] = koboldHealthBooster;
    }
}