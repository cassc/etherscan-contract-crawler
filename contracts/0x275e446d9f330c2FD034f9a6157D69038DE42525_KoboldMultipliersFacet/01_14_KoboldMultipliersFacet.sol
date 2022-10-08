// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import "@solidstate/contracts/access/ownable/Ownable.sol";
import "../libraries/LibKoboldMultipliers.sol";
import {KoboldStakingMultiplier}  from "../interfaces/IKoboldMultiplier.sol";
import "../libraries/LibAppStorage.sol";
///@author @0xSimon_

contract KoboldMultipliersFacet is Ownable {
    


    function setKoboldMultiplier(KoboldStakingMultiplier memory koboldStakingMultiplier) external onlyOwner  {
        LibKoboldMultipliers.setMultiplier(koboldStakingMultiplier);

    }

    //Returns a KoboldStakingMultiplier
    function getKoboldMultiplier(uint koboldMultiplierId) external view returns(KoboldStakingMultiplier memory) {
        KoboldStakingMultiplier memory multiplier = LibKoboldMultipliers.getKoboldMultiplier(koboldMultiplierId);
        if(bytes(multiplier.name).length == 0 ) revert ("Inexistent Multiplier");
       return LibKoboldMultipliers.getKoboldMultiplier(koboldMultiplierId);
    }
    //User Can Purchase Kobold Multiplier Using Ingot Token
    function purchaseKoboldMultiplier(uint koboldMultiplierId,uint quantity) external {
        address ingotAddress = LibAppStorage.getIngotTokenAddress();
        KoboldStakingMultiplier memory multiplier = LibKoboldMultipliers.getKoboldMultiplier(koboldMultiplierId);
        IERC20Like(ingotAddress).transferFrom(msg.sender,address(this),multiplier.price*quantity);
        LibKoboldMultipliers.purchaseMultiplier(msg.sender,koboldMultiplierId,quantity);
    }
    //We Get User Balance
    function getKoboldMultiplierUserBalance(address user, uint koboldMultiplerId) external view returns(uint) {
        return LibKoboldMultipliers.getUserBalance(user,koboldMultiplerId);
    }

    //Approve And Unapprove Multiplier Spenders... This Will Be Reserved For The Staking Contracts To Use
    function approveKoboldMultiplierSpender(address spender) external onlyOwner {
        LibKoboldMultipliers.approveSpender(spender);
    }
    function unapproveKoboldMultiplierSpender(address spender) external onlyOwner {
        LibKoboldMultipliers.unapproveSpender(spender);
    }

    function queryBatchKoboldMultipliers(uint[] calldata koboldMultiplierIds) external view returns(KoboldStakingMultiplier[] memory) {
        return LibKoboldMultipliers.queryBatchKoboldMultipliers(koboldMultiplierIds);
    }
    function queryUserBalanceBatchMultipliers(address account,uint[] calldata koboldMultiplierIds) external view returns(uint[] memory) {
         return LibKoboldMultipliers.queryUserBalanceBatchMultipliers(account,koboldMultiplierIds);
    }

    

 
}

interface IERC20Like {
    function transferFrom(address from, address to,uint amount) external;
}