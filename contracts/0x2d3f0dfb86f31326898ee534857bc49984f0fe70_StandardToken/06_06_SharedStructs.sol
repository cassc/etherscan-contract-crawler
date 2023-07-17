// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SharedStructs {
    struct status {
        uint256 mintflag;
        uint256 pauseflag;
        uint256 burnflag;
        uint256 blacklistflag;
    }
}