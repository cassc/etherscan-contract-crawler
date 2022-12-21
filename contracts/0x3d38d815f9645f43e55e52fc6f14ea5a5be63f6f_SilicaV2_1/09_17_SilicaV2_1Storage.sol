// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {SilicaV2_1Types} from "../libraries/SilicaV2_1Types.sol";

abstract contract SilicaV2_1Storage {
    uint32 public finishDay;
    bool public didSellerCollectPayout;
    address public rewardToken;
    address public paymentToken;
    address public oracleRegistry;
    address public silicaFactory;
    address public owner;

    uint32 public firstDueDay;
    uint32 public lastDueDay;
    uint32 public defaultDay;

    uint256 public initialCollateral;
    uint256 public resourceAmount;
    uint256 public reservedPrice;
    uint256 public rewardDelivered;
    uint256 public totalUpfrontPayment; //@review: why is it set to 1 as default in silicaV2
    uint256 public rewardExcess;
    SilicaV2_1Types.Status status;
}