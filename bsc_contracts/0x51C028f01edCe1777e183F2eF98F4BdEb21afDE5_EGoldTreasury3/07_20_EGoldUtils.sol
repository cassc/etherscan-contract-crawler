//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

library EGoldUtils {

    struct Ranks {
        uint256 percent;
        uint256 rankLimit;
    }

    struct userData {
        address parent;
        uint256 rank;
        uint256 sales;
        uint256 sn;
    }

    struct minerStruct{
        string uri;
        string name;
        uint256 hashRate;
        uint256 powerFactor;
        uint256 minerBaseRate;
    }

}