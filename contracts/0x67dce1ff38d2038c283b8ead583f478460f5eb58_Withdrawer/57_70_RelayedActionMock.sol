// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../actions/base/RelayedAction.sol';

contract RelayedActionMock is RelayedAction {
    // Cost in gas of a call op + gas cost computation + withdraw form SV
    uint256 public constant override BASE_GAS = 21e3 + 20e3;

    struct Config {
        BaseConfig baseConfig;
        RelayConfig relayConfig;
    }

    constructor(Config memory config) BaseAction(config.baseConfig) RelayedAction(config.relayConfig) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call() external actionCall(address(0), 0) {
        // solhint-disable-previous-line no-empty-blocks
    }
}