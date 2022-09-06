// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {LpDetail, LpAction} from "../fund/IFundAccount.sol";

struct TokenBalance {
    address token;
    uint256 balance;
    uint256 value;
}

struct LpDetailInfo {
    address lpAddr;
    LpDetail detail;
}

struct LPToken {
    uint256 tokenId;
    address token0;
    address token1;
    uint24 fee;
    uint256 amount0;
    uint256 amount1;
    uint256 fee0;
    uint256 fee1;
    uint256 amountValue0;
    uint256 amountValue1;
    uint256 feeValue0;
    uint256 feeValue1;
}

struct FundAccountData {
    address addr;
    // Block time when the account was opened
    uint256 since;
    // Fund create params
    string name;
    address gp;
    uint256 managementFee;
    uint256 carriedInterest;
    address underlyingToken;
    address initiator;
    uint256 initiatorAmount;
    address recipient;
    uint256 recipientMinAmount;
    address[] allowedProtocols;
    address[] allowedTokens;
    uint256 closed;

    // Fund runtime data
    uint256 totalUnit;
    uint256 totalManagementFeeAmount;
    uint256 totalCarryInterestAmount;
    // summary data
    uint256 ethBalance;
    uint256 totalValue;
    // extended data
    TokenBalance[] tokenBalances;
    LpDetailInfo[] lpDetailInfos;
    LPToken[] lpTokens;
}