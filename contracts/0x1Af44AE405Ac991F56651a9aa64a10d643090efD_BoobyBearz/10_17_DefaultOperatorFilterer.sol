// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor()
        OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true)
    {}
}