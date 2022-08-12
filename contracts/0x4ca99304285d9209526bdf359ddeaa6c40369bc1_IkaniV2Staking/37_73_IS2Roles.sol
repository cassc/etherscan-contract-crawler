// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IS2Storage } from "./IS2Storage.sol";

/**
 * @title IS2Storage
 * @author Cyborg Labs, LLC
 */
abstract contract IS2Roles is
    IS2Storage
{
    //---------------- Constants ----------------//

    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant UNPAUSER_ROLE = keccak256('UNPAUSER_ROLE');
    bytes32 public constant BASE_RATE_CONTROLLER_ROLE = keccak256('BASE_RATE_CONTROLLER_ROLE');
    bytes32 public constant BURN_CONTROLLER_ROLE = keccak256('BURN_CONTROLLER_ROLE');
    bytes32 public constant CLAIM_CONTROLLER_ROLE = keccak256('CLAIM_CONTROLLER_ROLE');
    bytes32 public constant UNSTAKE_CONTROLLER_ROLE = keccak256('UNSTAKE_CONTROLLER_ROLE');
}