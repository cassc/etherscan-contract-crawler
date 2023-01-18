// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./components/ViaRouterControls.sol";
import "./components/ViaRouterBase.sol";

contract ViaRouter is ViaRouterControls, ViaRouterBase {
    // INITIALIZER

    /// @notice Contract constructor, left for implementation initialization
    constructor() initializer {}

    /// @notice Upgradeable contract's initializer
    /// @param validator_ Address of the validator
    function initialize(address validator_) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        validator = validator_;
        emit ValidatorSet(validator_);
    }
}