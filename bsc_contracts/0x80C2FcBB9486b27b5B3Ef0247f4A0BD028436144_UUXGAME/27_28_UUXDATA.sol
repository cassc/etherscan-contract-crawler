// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface UUXDATA
{
    struct AssetStruct {
        bytes      name;
        uint256    amount;
    }
     struct SysConfigStruct {
        uint256     rechargePrice;
        uint256     zhiPrice;
        uint256     holderPrice;
        uint256     holderNum;
        uint256     holderPool;
        uint256     withdrawPercent;
        uint256     withdrawBei;
        uint256     uuxNo;
        uint256     uuxNo1;
        uint256     uuxNo2;
        uint256     noPrice;
        uint256     song1;
        uint256     song2;
    }
    struct LevelStruct{
        uint256  level;
        uint256  zhiNum;
        uint256  validNum;
        uint256  price;
        uint256  pingPrice;
        bool     enable;
    }
    struct UserHolderStruct{
        address owner;
    }
    struct UserTeamStruct{
        address owner;
        uint256 time;
    }
    struct RechargeStruct{
        uint256 price;
        uint256 no;
        uint256 time;
    }
    struct UserRebateStruct{
        address owner;
        uint256 price;
        uint256 types;
        uint256 level;
        uint256 time;
    }
}