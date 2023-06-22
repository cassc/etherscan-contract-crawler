// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "IStakefishTransactionFeePool.sol";

contract StakefishTransactionStorage {

    address internal adminAddress;
    address internal operatorAddress;
    address internal developerAddress;

    uint256 internal validatorCount;
    uint256 public stakefishCommissionRateBasisPoints;

    bool isOpenForWithdrawal;

    // depositor address => UserSummary
    mapping(address => IStakefishTransactionFeePool.UserSummary) internal users;
    // public key => validator is in pool
    mapping(bytes => address) internal validatorsInPool;

    // computation cache used to speedup payout computations
    IStakefishTransactionFeePool.ComputationCache internal cache;

}