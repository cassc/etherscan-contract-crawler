// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {TimelockControllerUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";
// import {GovernorTimelockControlUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import {Types} from "../libraries/types/Types.sol";

contract PolemarchStorage {
	mapping(address => Types.Exchequer) internal _exchequers;
	mapping(uint256 => address) internal _exchequersList;
	// mapping can delete lines of credit when it's closed and keep deliquent positions
	// can always just keep events to track historical data
	mapping(address => Types.LineOfCredit) internal _linesOfCredit;
	// both map to underlying assets
	uint256 internal _linesOfCreditCount;
	address internal _THURMAN;
	TimelockControllerUpgradeable _timelock;
	// GovernorTimelockControlUpgradeable _governor;
	uint16 internal _exchequersCount;
	uint16 internal _maxExchequersCount;
}