//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IOneInch {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }
}