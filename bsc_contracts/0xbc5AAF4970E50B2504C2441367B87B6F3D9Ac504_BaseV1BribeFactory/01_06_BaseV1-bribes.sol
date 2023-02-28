// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Bribe.sol';

contract BaseV1BribeFactory {
    address public last_bribe;

    function createBribe() external returns (address) {
        last_bribe = address(new Bribe(msg.sender));
        return last_bribe;
    }
}