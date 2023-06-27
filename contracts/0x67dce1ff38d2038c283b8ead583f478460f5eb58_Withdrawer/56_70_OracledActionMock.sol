// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../actions/base/OracledAction.sol';

contract OracledActionMock is OracledAction {
    event LogPrice(uint256 price);

    struct Config {
        BaseConfig baseConfig;
        OracleConfig oracleConfig;
    }

    constructor(Config memory config) BaseAction(config.baseConfig) OracledAction(config.oracleConfig) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getPrice(address base, address quote) external {
        emit LogPrice(_getPrice(base, quote));
    }
}