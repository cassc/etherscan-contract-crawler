// SPDX-License-Identifier: MIT
// Duplicated from https://github.com/ProjectOpenSea/operator-filter-registry/tree/v1.4.1
// Edited to use pragma ^0.8.0 and compile with Solidity 0.8.7
pragma solidity ^0.8.0;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "../lib/Constants.sol";

/**
 * @title  DefaultOperatorFiltererUpgradeable
 * @notice Inherits from OperatorFiltererUpgradeable and automatically subscribes to the default OpenSea subscription
 *         when the init function is called.
 */
abstract contract DefaultOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    /// @dev The upgradeable initialize function that should be called when the contract is being deployed.
    /// The original implementation was only allowing this function to be called on initialization, but
    /// this is incompatible with older versions of Solidity like 0.8.7, where an upgrade cannot be re-initialized.
    /// In order to fix this issue, this function has been split to provide a version that can be called without the
    /// onlyInitializing modifier.
    function __DefaultOperatorFilterer_init() internal onlyInitializing {
        _setupOperatorFilterer();
    }

    /// @dev Helper to setup the operator filterer that should be called upon an upgrade.
    function _setupOperatorFilterer() internal {
        OperatorFiltererUpgradeable._setupOperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true);
    }
}