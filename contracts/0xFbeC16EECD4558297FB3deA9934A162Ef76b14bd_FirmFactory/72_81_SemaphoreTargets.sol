// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {AddressUint8FlagsLib} from "../../bases/utils/AddressUint8FlagsLib.sol";

import {GnosisSafe} from "safe/GnosisSafe.sol";
import {Roles} from "../../roles/Roles.sol";
import {Budget} from "../../budget/Budget.sol";
import {Captable} from "../../captable/Captable.sol";
import {Voting} from "../../voting/Voting.sol";
import {Semaphore} from "../../semaphore/Semaphore.sol";

uint8 constant SEMAPHORE_TARGETS_FLAG_TYPE = 0x03;

enum SemaphoreTargetsFlag {
    Safe,
    Voting,
    Budget,
    Roles,
    Captable,
    Semaphore
}

struct FirmAddresses {
    GnosisSafe safe;
    Voting voting;
    Budget budget;
    Roles roles;
    Captable captable;
    Semaphore semaphore;
}

function exceptionTargetFlagToAddress(FirmAddresses memory firmAddresses, uint8 flagValue) pure returns (address) {
    SemaphoreTargetsFlag flag = SemaphoreTargetsFlag(flagValue);

    if (flag == SemaphoreTargetsFlag.Safe) {
        return address(firmAddresses.safe);
    } else if (flag == SemaphoreTargetsFlag.Semaphore) {
        return address(firmAddresses.semaphore);
    } else if (flag == SemaphoreTargetsFlag.Captable) {
        return address(firmAddresses.captable);
    } else if (flag == SemaphoreTargetsFlag.Voting) {
        return address(firmAddresses.voting);
    } else if (flag == SemaphoreTargetsFlag.Roles) {
        return address(firmAddresses.roles);
    } else if (flag == SemaphoreTargetsFlag.Budget) {
        return address(firmAddresses.budget);
    } else {
        assert(false); // if-else should be exhaustive and we should never reach here
        return address(0); // silence compiler warning, unreacheable 
    }
}

// Only used for testing/scripts
function targetFlag(SemaphoreTargetsFlag targetType) pure returns (address) {
    return AddressUint8FlagsLib.toFlag(uint8(targetType), SEMAPHORE_TARGETS_FLAG_TYPE);
}