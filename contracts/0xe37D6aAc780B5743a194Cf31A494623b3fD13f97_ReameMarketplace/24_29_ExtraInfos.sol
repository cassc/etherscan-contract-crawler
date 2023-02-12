// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library ExtraInfos 
{
     struct ExtraInfoV2 {
        uint32 value1;
        uint32 value2;
        uint32 value3;
        uint32 value4;
        uint32 value5;
        uint32 value6;
        uint32 value7;
        uint32 value8;
        uint32 value9;
        uint32 value10;
    }

    struct ExtraInfoParams {
        uint32[] values1;
        uint32[] values2;
        uint32[] values3;
        uint32[] values4;
        uint32[] values5;
        uint32[] values6;
        uint32[] values7;
        uint32[] values8;
        uint32[] values9;
        uint32[] values10;
    }
}