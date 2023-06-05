// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface ISDTDistributor {
	function distribute(address gaugeAddr) external;
}