// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface PriceOracleDataTypes {
	struct PriceDataOut {
		uint64 price;
		uint64 timestamp;
	}
}