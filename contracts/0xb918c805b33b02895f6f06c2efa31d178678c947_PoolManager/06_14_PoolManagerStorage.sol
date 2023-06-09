// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IPoolManagerStorage } from "../interfaces/IPoolManagerStorage.sol";

abstract contract PoolManagerStorage is IPoolManagerStorage {

    uint256 internal _locked;  // Used when checking for reentrancy.

    address public override poolDelegate;
    address public override pendingPoolDelegate;

    address public override asset;
    address public override pool;

    address public override poolDelegateCover;
    address public override withdrawalManager;

    bool public override active;
    bool public override configured;
    bool public override openToPublic;

    uint256 public override liquidityCap;
    uint256 public override delegateManagementFeeRate;

    mapping(address => bool) public override isLoanManager;
    mapping(address => bool) public override isValidLender;

    address[] public override loanManagerList;

}