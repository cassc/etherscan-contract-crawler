// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {JBFee} from './../structs/JBFee.sol';
import {JBDidRedeemData3_1_1} from './../structs/JBDidRedeemData3_1_1.sol';
import {JBDidPayData3_1_1} from './../structs/JBDidPayData3_1_1.sol';
import {IJBPayDelegate3_1_1} from './IJBPayDelegate3_1_1.sol';
import {IJBRedemptionDelegate3_1_1} from './IJBRedemptionDelegate3_1_1.sol';
import {IJBPayoutRedemptionPaymentTerminal3_1} from './IJBPayoutRedemptionPaymentTerminal3_1.sol';

interface IJBPayoutRedemptionPaymentTerminal3_1_1 is IJBPayoutRedemptionPaymentTerminal3_1 {
  event DelegateDidRedeem(
    IJBRedemptionDelegate3_1_1 indexed delegate,
    JBDidRedeemData3_1_1 data,
    uint256 delegatedAmount,
    uint256 fee,
    address caller
  );

  event DelegateDidPay(
    IJBPayDelegate3_1_1 indexed delegate,
    JBDidPayData3_1_1 data,
    uint256 delegatedAmount,
    address caller
  );
}