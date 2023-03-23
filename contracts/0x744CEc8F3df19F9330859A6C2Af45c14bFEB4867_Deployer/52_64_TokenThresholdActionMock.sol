// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../actions/TokenThresholdAction.sol';

contract TokenThresholdActionMock is TokenThresholdAction {
    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call(address token, uint256 amount) external view {
        _validateThreshold(token, amount);
    }
}