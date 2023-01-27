// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {InitializableOperatorFilterer} from "./InitializableOperatorFilterer.sol";

/**
 * @title  InitializableDefaultOperatorFilterer
 * @notice Inherits from InitializableOperatorFilterer and automatically subscribes to the default OpenSea subscription during initialization.
 */
abstract contract InitializableDefaultOperatorFilterer is InitializableOperatorFilterer {
    
    /// @dev The default subscription address
    address internal constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    /// @dev The parameters are ignored, and the default subscription values are used instead.
    function initializeOperatorFilterer(address /*subscriptionOrRegistrantToCopy*/, bool /*subscribe*/) public virtual override {
        super.initializeOperatorFilterer(DEFAULT_SUBSCRIPTION, true);
    }
}