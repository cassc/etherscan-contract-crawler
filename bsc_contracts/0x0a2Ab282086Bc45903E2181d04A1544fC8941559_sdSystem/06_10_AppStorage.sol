//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;

uint constant MAX_INT = type(uint).max;
uint constant DEPOSIT_HOLD = 15; // 600;
address constant WBNB_ADDR = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
bytes32 constant HARVESTER = keccak256("HARVESTER");

struct stData {
    address lpContract;
    address beaconContract;
    address feeCollector;
    address token0;
    address token1;

    string  exchange;

    uint poolId;
    uint dust;        
    uint poolTotal;
    uint unitsTotal;
    uint depositTotal;
    uint withdrawTotal;
    uint lastProcess;
    uint lastDiscount;
    bool paused;
}

struct sHolders {
    uint amount;
    uint holdback;
    uint depositDate;
    uint discount;
    uint discountValidTo;    
    uint accumulatedRewards;    
    
    uint _pos;
}

struct transHolders {
    bool deposit;
    uint amount;
    uint timestamp;
    address account;
}

struct sendQueue {
    address user;
    uint amount;
}

struct sExchangeInfo {
    address chefContract;
    address routerContract;
    address rewardToken;
    address intermediateToken;
    address baseToken;
    string pendingCall;
    string contractType_solo;
    string contractType_pooled;
    bool psV2;
}


struct AppStorage {
    bool _locked;
    bool _initialized;
    bool _shared;
    bool liquidationFee;
    bool paused;

    uint256 lastGas;
    uint256 SwapFee; // 8 decimal places
    address migrateFrom;
    address intToken0;
    address intToken1;

    string revision;
    mapping (address => bool) adminUsers;
    mapping (address => bool) godUsers;

    stData iData;
    sExchangeInfo exchangeInfo;
    
    mapping (address=>sHolders) iHolders;
    address[] iQueue;

    transHolders[] transactionLog;
}