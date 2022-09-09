// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    GelatoRelayContext
} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";

contract Counter is GelatoRelayContext {
    uint256 public counter;

    event IncrementCounter();

    function increment() external onlyGelatoRelay {
        // payment to Gelato
        _transferRelayFee();

        // logic
        counter += 1;
        emit IncrementCounter();
    }

    function currentCounter() external view returns (uint256) {
        return counter;
    }
}