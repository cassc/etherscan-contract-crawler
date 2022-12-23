// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperEmergency {
    modifier onlyEmergencyDisabled() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(!s.emergencyShutdown);

        _;
    }
}