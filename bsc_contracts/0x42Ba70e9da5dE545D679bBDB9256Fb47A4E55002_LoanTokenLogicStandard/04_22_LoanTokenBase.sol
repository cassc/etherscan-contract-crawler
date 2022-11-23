/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "SafeMath.sol";
import "SignedSafeMath.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";
import "Address.sol";
import "IWethERC20.sol";
import "PausableGuardian.sol";


contract LoanTokenBase is ReentrancyGuard, Ownable, PausableGuardian {

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    int256 internal constant sWEI_PRECISION = 10**18;

    string public name;
    string public symbol;
    uint8 public decimals;

    // uint88 for tight packing -> 8 + 88 + 160 = 256
    uint88 internal lastSettleTime_;

    address public loanTokenAddress;

    uint256 internal baseRate_UNUSED;
    uint256 internal rateMultiplier_UNUSED;
    uint256 internal lowUtilBaseRate_UNUSED;
    uint256 internal lowUtilRateMultiplier_UNUSED;
    uint256 internal targetLevel_UNUSED;
    uint256 internal kinkLevel_UNUSED;
    uint256 internal maxScaleRate_UNUSED;

    uint256 internal _flTotalAssetSupply;
    uint256 internal checkpointSupply_UNUSED;
    uint256 public initialPrice;

    mapping (uint256 => bytes32) public loanParamsIds; // mapping of keccak256(collateralToken, isTorqueLoan) to loanParamsId
    mapping (address => uint256) internal checkpointPrices_DEPRECATED; // price of token at last user checkpoint
}