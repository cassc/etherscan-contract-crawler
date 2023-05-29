// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesStakingStruct {

    struct Staking {
        uint8 slotIndex;
        uint16 tokenId;
        uint16 origin;
        uint64 timestampV2;
        address owner;
    }

    struct Origin{
        uint8 maxSlots;
        uint16[] stacked;
    }

}