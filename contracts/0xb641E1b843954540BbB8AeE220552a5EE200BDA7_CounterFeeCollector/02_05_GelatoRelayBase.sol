// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {GELATO_RELAY} from "../constants/GelatoRelay.sol";

abstract contract GelatoRelayBase {
    modifier onlyGelatoRelay() {
        require(
            _isGelatoRelay(msg.sender),
            "GelatoRelayContext.onlyGelatoRelay"
        );
        _;
    }

    function _isGelatoRelay(address _forwarder) internal pure returns (bool) {
        return _forwarder == GELATO_RELAY;
    }
}