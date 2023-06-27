// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../actions/base/TimeLockedAction.sol';

contract TimeLockedActionMock is TimeLockedAction {
    struct Config {
        BaseConfig baseConfig;
        TimeLockConfig timeLockConfig;
    }

    constructor(Config memory config) BaseAction(config.baseConfig) TimeLockedAction(config.timeLockConfig) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call() external actionCall(address(0), 0) {
        // solhint-disable-previous-line no-empty-blocks
    }
}