// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../actions/base/TokenThresholdAction.sol';

contract TokenThresholdActionMock is TokenThresholdAction {
    struct Config {
        BaseConfig baseConfig;
        TokenThresholdConfig tokenThresholdConfig;
    }

    constructor(Config memory config) BaseAction(config.baseConfig) TokenThresholdAction(config.tokenThresholdConfig) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call(address token, uint256 amount) external actionCall(token, amount) {
        // solhint-disable-previous-line no-empty-blocks
    }
}