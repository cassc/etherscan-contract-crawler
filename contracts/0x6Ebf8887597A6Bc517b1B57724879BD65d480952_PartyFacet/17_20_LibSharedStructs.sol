// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibSharedStructs {
    struct Allocation {
        address[] sellTokens;
        uint256[] sellAmounts;
        address[] buyTokens;
        address[] spenders;
        address payable[] swapsTargets;
        bytes[] swapsCallData;
        uint256 partyValueDA;
        uint256 partyTotalSupply;
        uint256 expiresAt;
    }

    struct FilledQuote {
        address sellToken;
        address buyToken;
        uint256 soldAmount;
        uint256 boughtAmount;
        uint256 initialSellBalance;
        uint256 initialBuyBalance;
    }

    struct Allocated {
        address[] sellTokens;
        address[] buyTokens;
        uint256[] soldAmounts;
        uint256[] boughtAmounts;
    }
}