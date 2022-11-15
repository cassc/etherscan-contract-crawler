// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Util {
    struct Tax {
        uint256 _marketingFee;
        uint256 _devFee;
        uint256 _liquidityFee;
        uint256 _totalFee;
    }

    enum TaxIdentifier {
        BUY,
        SELL
    }
}