// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../actions/ReceiverAction.sol';

contract ReceiverActionMock is ReceiverAction {
    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }
}