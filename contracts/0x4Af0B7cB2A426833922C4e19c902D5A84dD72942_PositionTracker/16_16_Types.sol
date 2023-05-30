// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import {IERC20MetadataUpgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

enum PoolType{
    LENDING_ONE_TO_MANY,
    BORROWING_ONE_TO_MANY
}

/* ========== STRUCTS ========== */
struct DeploymentParameters {
    uint256 lendRatio;
    address colToken;
    address lendToken;
    bytes32 feeRatesAndType;
    PoolType poolType;
    bytes32 strategy;
    address[] allowlist;
    uint256 initialDeposit;
    uint48 expiry;
    uint48 ltv;
    uint48 pauseTime;
}

struct FactoryParameters {
    address feesManager;
    bytes32 strategy;
    address oracle;
    address treasury;
    address posTracker;
}

struct GeneralPoolSettings {
    PoolType poolType;
    address owner;
    uint48 expiry;
    IERC20 colToken;
    uint48 protocolFee;
    IERC20 lendToken;
    uint48 ltv;
    uint48 pauseTime;
    uint256 lendRatio;
    address[] allowlist;
    bytes32 feeRatesAndType;
}