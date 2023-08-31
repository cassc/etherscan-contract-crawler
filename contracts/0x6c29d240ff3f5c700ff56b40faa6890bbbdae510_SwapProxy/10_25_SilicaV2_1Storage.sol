/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |  <|  | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SilicaV2_1Types} from "../libraries/SilicaV2_1Types.sol";

/**
 * @title  Alkimiya Silica Storage 
 * @author Alkimiya Team
 * @notice This is base storage to be inherited by derived Silica contracts
 * */
abstract contract SilicaV2_1Storage {
    
    address public rewardToken; //Slot 0
    address public paymentToken; //Slot 1
    address public oracleRegistry; //Slot 2

    address public owner; //Slot 3
    uint32 public finishDay; //Slot 3
    uint32 public firstDueDay; //Slot 3
    uint32 public lastDueDay; //Slot 3

    address public silicaFactory; //Slot 4
    uint32 public defaultDay; //Slot 4
    bool public didSellerCollectPayout; //Slot 4
    SilicaV2_1Types.Status status;

    uint256 public initialCollateral; //Slot 5
    uint256 public resourceAmount;
    uint256 public reservedPrice;
    uint256 public rewardDelivered;
    uint256 public totalUpfrontPayment; 
    uint256 public rewardExcess;
    
}