// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./PriceOracleDataTypes.sol";

interface PriceOracleInterface is PriceOracleDataTypes {
	function assetPrices(address) external view returns (PriceDataOut memory);

	function givePrices(address[] calldata assetAddresses) external view returns (PriceDataOut[] memory);
}