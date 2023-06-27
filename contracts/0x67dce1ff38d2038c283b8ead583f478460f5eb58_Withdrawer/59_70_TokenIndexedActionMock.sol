// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../actions/base/TokenIndexedAction.sol';

contract TokenIndexedActionMock is TokenIndexedAction {
    struct Config {
        BaseConfig baseConfig;
        TokenIndexConfig tokenIndexConfig;
    }

    constructor(Config memory config) BaseAction(config.baseConfig) TokenIndexedAction(config.tokenIndexConfig) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call(address token) external actionCall(token, 0) {
        // solhint-disable-previous-line no-empty-blocks
    }
}