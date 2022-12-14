// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Types {
    struct Stream {
        uint256 streamId;
        address sender;
        uint256 releaseAmount;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime; 
        uint256 vestingAmount;
        uint256 releaseFrequency;
        uint8 transferPrivilege;
        uint8 cancelPrivilege;
        address recipient;
        address tokenAddress;
        uint8 status;
    }

    struct Fee {
        address tokenAddress;
        uint256 fee;
    }

    struct WithdrawFeeAddress {
        address allowAddress;
        uint32 percentage;
    }

}