// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library Types {
  struct Exchequer {
    uint128 supplyIndex;
    uint128 supplyRate;
    uint40 lastUpdateTimestamp;
    uint16 id;
    uint8 decimals;
    bool active;
    bool borrowingEnabled;
    uint256 protocolBorrowFee;
    uint256 totalDebt;
    uint256 borrowCap;
    uint256 supplyCap;
    uint256 collateralFactor; // expressed in ray
    address sTokenAddress;
    address dTokenAddress;
    address gTokenAddress;
    uint128 accruedToExchequerSafe;
  }

  // a user can only have one open line of credit and LoCs are closed when the balance is zero
  // the balance can be tracked through dToken state
  struct LineOfCredit {
    uint256 borrowMax;
    address underlyingAsset;
    // uint256 rate; // interest should accrue per second => rate based on per second accrual
    uint40 lastRepaymentTimestamp;
    uint40 creationTimestamp;
    uint40 expirationTimestamp;
    uint128 id;
    bool deliquent;
  }
}