/**************************
  ___  ____  ____  ____   ___   ___  ____    ___    
|_  ||_  _||_  _||_  _|.'   `.|_  ||_  _| .'   `.  
  | |_/ /    \ \  / / /  .-.  \ | |_/ /  /  .-.  \ 
  |  __'.     \ \/ /  | |   | | |  __'.  | |   | | 
 _| |  \ \_   _|  |_  \  `-'  /_| |  \ \_\  `-'  / 
|____||____| |______|  `.___.'|____||____|`.___.'  

 **************************/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ICreditSystem {
    function getCCALCreditLine(address user) external returns(uint);
    function getState(address user) external returns(bool, bool);
}

interface ICCAL {
    enum Operation { BORROW, REPAY, LIQUIDATE }

    enum AssetStatus { INITIAL, BORROW, REPAY, WITHDRAW, LIQUIDATE }

    struct TokenInfo {
        uint8 decimals;
        bool active;
        bool stable;
    }

    struct DepositAsset {
        uint cycle;
        uint minPay;
        uint borrowTime;
        uint depositTime;
        uint totalAmount;
        uint amountPerDay;
        uint internalId;
        uint borrowIndex;
        address borrower;
        address token;
        address game;
        address holder;
        AssetStatus status;
        uint[] toolIds;
    }

    struct FreezeTokenInfo {
        address operator;
        bool useCredit;
        uint amount;
        address token;
    }

    struct InterestInfo {
        uint internalId;
        uint16 chainId;
        uint amount;
        uint borrowIndex;
        address token;
    }
}