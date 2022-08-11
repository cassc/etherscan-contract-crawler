// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

interface IAddressConfig {
	function lockup() external view returns (address);
}