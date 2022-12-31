// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import {Swap} from "../types/types.sol";

enum ExchangeStatus {
	PROCESSED,
	REFUNDED,
	CLOSED
}

interface IAliumMulitichain {
	function addAdapter(address) external;
	function setAdapter(address, address) external;
	function removeAdapter(address) external;

	function setEventLogger(address) external;
	function eventLogger() external view returns (address);

	function nonce() external view returns (uint256);
	function applyNonce() external returns (uint256);

	function trades(uint256) external view returns (Swap memory);
	function applyTrade(uint256, Swap calldata) external;

	function vault() external view returns (address);
}