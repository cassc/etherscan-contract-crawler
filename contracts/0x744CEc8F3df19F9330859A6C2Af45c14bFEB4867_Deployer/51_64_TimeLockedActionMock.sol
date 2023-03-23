// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../actions/TimeLockedAction.sol';

contract TimeLockedActionMock is TimeLockedAction {
    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call() external {
        _validateTimeLock();
    }
}