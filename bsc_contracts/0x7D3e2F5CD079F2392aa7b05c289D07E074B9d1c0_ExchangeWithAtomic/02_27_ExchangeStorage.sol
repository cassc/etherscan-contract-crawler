// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC20.sol";
import "./libs/MarginalFunctionality.sol";

// Base contract which contain state variable of the first version of Exchange
// deployed on mainnet. Changes of the state variables should be introduced
// not in that contract but down the inheritance chain, to allow safe upgrades
// More info about safe upgrades here:
// https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/#upgrade-patterns

contract ExchangeStorage {

    //order -> filledAmount
    mapping(bytes32 => uint192) public filledAmounts;


    // Get user balance by address and asset address
    mapping(address => mapping(address => int192)) internal assetBalances;
    // List of assets with negative balance for each user
    mapping(address => MarginalFunctionality.Liability[]) public liabilities;
    // List of assets which can be used as collateral and risk coefficients for them
    address[] internal collateralAssets;
    mapping(address => uint8) public assetRisks;
    // Risk coefficient for locked ORN
    uint8 public stakeRisk;
    // Liquidation premium
    uint8 public liquidationPremium;
    // Delays after which price and position become outdated
    uint64 public priceOverdue;
    uint64 public positionOverdue;

    // Base orion tokens (can be locked on stake)
    IERC20 _orionToken;
    // Address of price oracle contract
    address _oracleAddress;
    // Address from which matching of orders is allowed
    address _allowedMatcher;

}