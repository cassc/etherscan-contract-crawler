// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;
import {KoboldStakingMultiplier}  from "../interfaces/IKoboldMultiplier.sol";

///@author @0xSimon_

library LibKoboldMultipliers {
    //Storage
    bytes32 internal constant NAMESPACE = keccak256("titanforge.kobold.multipliers");

    struct Storage{
        mapping(uint => KoboldStakingMultiplier) multipliers;
        mapping(address => mapping(uint => uint)) balanceOf;
        mapping(address => bool) approvedPurchaser;
        mapping(address => bool) approvedSpender;
        uint koboldMultiplierIdTracker;
    }
    
    function getStorage() internal pure returns(Storage storage s)  {
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
    function purchaseMultiplier(address from,uint koboldMultiplierId,uint quantity) internal {
        Storage storage s = getStorage();
        KoboldStakingMultiplier memory multiplier = s.multipliers[koboldMultiplierId];
        require(multiplier.isAvailableForPurchase,"Not For Sale");
        if(multiplier.quantitySold + quantity > multiplier.maxQuantity) revert ("Sold Out");
        s.multipliers[koboldMultiplierId].quantitySold = multiplier.quantitySold + quantity;
        s.balanceOf[from][koboldMultiplierId] += quantity;
    }
    function spendMultiplier(address from,uint koboldMultiplierId,uint quantity) internal {
        Storage storage s = getStorage();
        if(msg.sender != tx.origin) {
        require(s.approvedSpender[msg.sender] , "Not Approved Spender");
        }
        if(quantity > s.balanceOf[from][koboldMultiplierId]) revert ("Kobold Multiplier: Insufficient Multiplier Balance");
        s.balanceOf[from][koboldMultiplierId] -= quantity;
    }
    function getKoboldMultiplier(uint koboldMultiplierId) internal view returns(KoboldStakingMultiplier memory) {
        Storage storage s = getStorage();
        return s.multipliers[koboldMultiplierId];
    }
    function queryBatchKoboldMultipliers(uint[] calldata koboldMultiplierIds) internal view returns(KoboldStakingMultiplier[] memory) {
            uint len = koboldMultiplierIds.length;
            KoboldStakingMultiplier[]  memory koboldStakingMultipliers = new KoboldStakingMultiplier[](len);
            for(uint i; i < len;){
                uint id = koboldMultiplierIds[i];
                koboldStakingMultipliers[i] = getKoboldMultiplier(id);
                 unchecked{++i;}
            }
            return koboldStakingMultipliers;
    }

    function queryUserBalanceBatchMultipliers(address account,uint[] calldata koboldMultiplierIds) internal view returns(uint[] memory) {
            uint len = koboldMultiplierIds.length;
            uint[]  memory koboldStakingMultipliers = new uint[](len);
            for(uint i; i < len;){
                uint id = koboldMultiplierIds[i];
                koboldStakingMultipliers[i] = getUserBalance(account,id);
                 unchecked{++i;}
            }
            return koboldStakingMultipliers;
    }

    function getUserBalance(address user,uint koboldMultiplierId) internal view returns(uint) {
        Storage storage s = getStorage();
        return s.balanceOf[user][koboldMultiplierId];
    }
    function approveSpender(address spender) internal {
        Storage storage s = getStorage();
        s.approvedSpender[spender] = true;
    }
    function unapproveSpender(address spender) internal {
        Storage storage s = getStorage();
        delete s.approvedSpender[spender];
    }
    function setMultiplier(KoboldStakingMultiplier memory koboldStakingMultiplier) internal {
        Storage storage s = getStorage();
        s.multipliers[s.koboldMultiplierIdTracker] = koboldStakingMultiplier;
        ++s.koboldMultiplierIdTracker;
    }

    function overrideExistingMultiplier(uint multiplierId,KoboldStakingMultiplier memory koboldStakingMultiplier) internal {
        Storage storage s = getStorage();
          s.multipliers[multiplierId] = koboldStakingMultiplier;
    }
}