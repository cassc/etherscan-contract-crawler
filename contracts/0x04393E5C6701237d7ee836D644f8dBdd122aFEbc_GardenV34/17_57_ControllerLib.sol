// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBabController} from '../interfaces/IBabController.sol';

library ControllerLib {
    /**
     * Throws if the sender is not the protocol
     */
    function onlyGovernanceOrEmergency(IBabController _controller) internal view {
        require(
            msg.sender == _controller.owner() || msg.sender == _controller.EMERGENCY_OWNER(),
            'Only governance or emergency can call this'
        );
    }
}