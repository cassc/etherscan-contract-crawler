// SPDX-License-Identifier: GPL
pragma solidity ^0.8.7;
import "@gnosis.pm/safe-contracts/contracts/examples/libraries/GnosisSafeStorage.sol";

// adopted from: https://github.com/safe-global/safe-contracts/blob/main/contracts/examples/libraries/Migrate_1_3_0_to_1_2_0.sol
contract UpdateSingleton is GnosisSafeStorage {
    address public immutable self;

    constructor() {
        self = address(this);
    }

    event ChangedMasterCopy(address singleton);

    bytes32 private guard;

    function update(address targetSingleton) public {
        require(targetSingleton != address(0), "Invalid singleton address provided");

        // Can only be called via a delegatecall.
        require(address(this) != self, "Migration should only be called via delegatecall");

        singleton = targetSingleton;
        emit ChangedMasterCopy(singleton);
    }
}