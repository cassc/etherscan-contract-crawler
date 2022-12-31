// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Policy {
    enum PolicyType {
        ETH,    // 0
        USDC    // 1
    }

    struct PolicyPrice {
        uint256 earlyUSDCPrice;
        uint256 publicUSDCPrice;
        uint256 earlyETHPrice;
        uint256 publicETHPrice;
    }

    struct Cover {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 lengthDays;
        PolicyType paymentType;
    }
}