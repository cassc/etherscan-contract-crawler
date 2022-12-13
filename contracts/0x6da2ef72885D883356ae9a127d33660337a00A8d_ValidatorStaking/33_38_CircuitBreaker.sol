// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/CircuitBreakerErrors.sol";

abstract contract CircuitBreaker {
    // constants for the cb state
    bool internal constant _CIRCUIT_BREAKER_CLOSED = false;
    bool internal constant _CIRCUIT_BREAKER_OPENED = true;

    // Same as _CIRCUIT_BREAKER_CLOSED
    bool internal _circuitBreaker;

    // withCircuitBreaker is a modifier to enforce the CircuitBreaker must
    // be set for a call to succeed
    modifier withCircuitBreaker() {
        if (_circuitBreaker == _CIRCUIT_BREAKER_OPENED) {
            revert CircuitBreakerErrors.CircuitBreakerOpened();
        }
        _;
    }

    function circuitBreakerState() public view returns (bool) {
        return _circuitBreaker;
    }

    function _tripCB() internal {
        if (_circuitBreaker == _CIRCUIT_BREAKER_OPENED) {
            revert CircuitBreakerErrors.CircuitBreakerOpened();
        }

        _circuitBreaker = _CIRCUIT_BREAKER_OPENED;
    }

    function _resetCB() internal {
        if (_circuitBreaker == _CIRCUIT_BREAKER_CLOSED) {
            revert CircuitBreakerErrors.CircuitBreakerClosed();
        }

        _circuitBreaker = _CIRCUIT_BREAKER_CLOSED;
    }
}