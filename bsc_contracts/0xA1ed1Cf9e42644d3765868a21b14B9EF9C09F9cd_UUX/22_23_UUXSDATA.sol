// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface UUXSDATA
{
     struct SysConfigStruct {
        uint256  minHold;
        uint256  buyService;
        uint256  sellService;
        uint256  burnService;
        uint256  runService;
        uint256  userService;
        address  serviceAddress;
        address  runAddress;
    }
}