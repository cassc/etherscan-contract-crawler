// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;
pragma abicoder v2;

import './NToken.sol';

contract NTokenFactory {
    function deployNToken(bytes32 salt) external returns (address nToken) {
        nToken = address(new NToken{salt: salt}());
    }
}