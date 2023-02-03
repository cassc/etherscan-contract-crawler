// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface PriceOracleDataTypes {
    struct PriceDataOut {
        uint64 price;
        uint64 timestamp;
    }

}