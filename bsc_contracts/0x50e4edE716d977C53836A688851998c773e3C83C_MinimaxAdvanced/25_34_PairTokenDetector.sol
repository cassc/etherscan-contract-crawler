// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPairToken.sol";

contract PairTokenDetector {
    function isPairToken(address a) external view returns (bool) {
        bool success;
        bytes memory response;

        (success, response) = a.staticcall(abi.encodeWithSelector(IPairToken.token0.selector));
        if (!(success && response.length == 32)) {
            return false;
        }

        (success, response) = a.staticcall(abi.encodeWithSelector(IPairToken.token1.selector));
        if (!(success && response.length == 32)) {
            return false;
        }

        (success, response) = a.staticcall(abi.encodeWithSelector(IPairToken.totalSupply.selector));
        if (!(success && response.length == 32)) {
            return false;
        }

        (success, response) = a.staticcall(abi.encodeWithSelector(IPairToken.getReserves.selector));
        if (!(success && response.length == 96)) {
            return false;
        }

        return true;
    }
}