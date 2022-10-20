// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import "@solidstate/contracts/access/ownable/Ownable.sol";
import "../libraries/LibKoboldHealthBoosters.sol";
import {KoboldHealthBooster}  from "../interfaces/IKoboldHealthBooster.sol";
import "../libraries/LibAppStorage.sol";

///@author @0xSimon_

contract KoboldHealthBoosterFacet is Ownable {
    


    function setKoboldHealthBooster(KoboldHealthBooster memory koboldHealthBooster) external onlyOwner  {
        LibKoboldHealthBoosters.setKoboldHealthBooster(koboldHealthBooster);

    }

    //Returns a KoboldHealthBooster
    function getKoboldHealthBooster(uint koboldHealthBoosterId) external view returns(KoboldHealthBooster memory) {
        KoboldHealthBooster memory healthBooster = LibKoboldHealthBoosters.getKoboldHealthBooster(koboldHealthBoosterId);
        if(bytes(healthBooster.name).length == 0 ) revert ("Inexistent healthBooster");
       return healthBooster;
    }
    //User Can Purchase Kobold healthBooster Using Ingot Token
    function purchaseKoboldHealthBooster(uint koboldHealthBoosterId,uint quantity) external {
        address ingotAddress = LibAppStorage.getIngotTokenAddress();
        KoboldHealthBooster memory healthBooster = LibKoboldHealthBoosters.getKoboldHealthBooster(koboldHealthBoosterId);
        IERC20Like(ingotAddress).transferFrom(msg.sender,address(this),healthBooster.price*quantity);
        LibKoboldHealthBoosters.purchaseKoboldHealthBooster(msg.sender,koboldHealthBoosterId,quantity);
    }
    //We Get User Balance
    function getKoboldHealthBoosterUserBalance(address user, uint koboldHealthBoosterId) external view returns(uint) {
        return LibKoboldHealthBoosters.getKoboldHealthBoosterBalance(user,koboldHealthBoosterId);
    }

    //Approve And Unapprove healthBooster Spenders... This Will Be Reserved For The Staking Contracts To Use
    function approveKoboldHealthBoosterSpender(address spender) external onlyOwner {
        LibKoboldHealthBoosters.approveKoboldHealthBoosterSpender(spender);
    }
    function unapproveKoboldHealthBoosterSpender(address spender) external onlyOwner {
        LibKoboldHealthBoosters.unapproveKoboldHealthBoosterSpender(spender);
    }

    function queryBatchKoboldHealthBoosters(uint[] calldata koboldHealthBoosterIds) external view returns(KoboldHealthBooster[] memory) {
        return LibKoboldHealthBoosters.queryBatchKoboldHealthBoosters(koboldHealthBoosterIds);
    }
    function queryUserBalanceBatchHealthBoosters(address account,uint[] calldata koboldHealthBoosterIds) external view returns(uint[] memory) {
         return LibKoboldHealthBoosters.queryUserBalanceBatchHealthBoosters(account,koboldHealthBoosterIds);
    }

    function useKoboldHealthBooster(address from,uint koboldTokenId,uint koboldHealthBoosterId,uint quantity) external {
        LibKoboldHealthBoosters.useKoboldHealthBooster(from,koboldTokenId,koboldHealthBoosterId,quantity);
    }

}

interface IERC20Like {
    function transferFrom(address from, address to,uint amount) external;
}