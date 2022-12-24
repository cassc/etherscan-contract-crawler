// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperActors {
    modifier onlyPendingGovernance() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.pendingGovernance);

        _;
    }

    modifier onlyGovernance() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance);

        _;
    }

    modifier onlyGovernanceOrManagement() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance || msg.sender == s.management);

        _;
    }

    modifier onlyGovernanceOrWithdrawGuardian() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance || msg.sender == s.withdrawGuardian);

        _;
    }
}