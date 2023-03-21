// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// import {GovernorTimelockControlUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import {TimelockControllerUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";
import {Types} from "../protocol/libraries/types/Types.sol";

interface IPolemarch {
	event Supply(address indexed exchequer, address indexed user, uint256 amount);
	event GrantSupply(address indexed exchequer, address indexed user, uint256 amount);
	event Withdraw(address indexed exchequer, address indexed user, uint256 amount);
	event CreateLineOfCredit(
		uint128 indexed id,
		uint128 rate,
		address indexed borrower,
		address indexed exchequer,
		uint256 borrowMax,
		uint40 expirationTimestamp
	);
	event Borrow(
		uint128 indexed lineOfCreditId,
		uint128 rate,
		address indexed borrower,
		address indexed exchequer,
		uint256 amount
	);
	event Repay(
		uint128 indexed lineOfCreditId,
		address indexed borrower,
		address indexed exchequer,
		uint256 amount
	);

	event Delinquent(
		uint128 indexed lineOfCreditId,
		address indexed borrower,
		address indexed exchequer,
		uint256 remainingBalance,
		uint40 expirationTimestamp
	);

	event CloseLineOfCredit(
		uint128 indexed lineOfCreditId,
		address indexed borrower,
		address indexed exchequer,
		uint40 expirationTimestamp
	);

	function supply(address underlyingAsset, uint256 amount) external;

	function grantSupply(address underlyingAsset, uint256 amount) external;
	
	function withdraw(address underlyingAsset, uint256 amount) external;

	function createLineOfCredit(
		address borrower,
		address underlyingAsset,
		uint256 borrowMax,
		uint128 rate,
		uint40 termDays
	) external;

	function borrow(address underlyingAsset, uint256 amount) external;

	function repay(address underlyingAsset, uint256 amount) external;

	function markDelinquent(address underlyingAsset, address borrower) external;

	function closeLineOfCredit(address underlyingAsset, address borrower) external;

	function addExchequer(
		address underlyingAsset, 
		address sTokenAddress, 
		address dTokenAddress, 
		address gTokenAddress,
		uint8 decimals,
		uint256 protocolBorrowFee
	) external;

	function deleteExchequer(address underlyingAsset) external;

	function getExchequer(address underlyingAsset) external view returns (Types.Exchequer memory);

	function getLineOfCredit(address borrower) external view returns (Types.LineOfCredit memory);

	function getNormalizedReturn(address underlyingAsset) external view returns (uint256);

	function setExchequerBorrowing(address underlyingAsset, bool enabled) external;

	function setTimelock(TimelockControllerUpgradeable timelock) external;

	// function setGovernor(GovernorTimelockControlUpgradeable governor) external;

	function setExchequerActive(address underlyingAsset, bool active) external;

	function setSupplyCap(address underlyingAsset, uint256 supplyCap) external;

	function setBorrowCap(address underlyingAsset, uint256 borrowCap) external;
}