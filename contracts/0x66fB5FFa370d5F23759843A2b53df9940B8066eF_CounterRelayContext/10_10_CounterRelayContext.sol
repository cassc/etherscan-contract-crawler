// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    GelatoRelayContext
} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";

// Inheriting GelatoRelayContext gives access to:
// 1. _getFeeCollector(): returns the address of Gelato's feeCollector
// 2. _getFeeToken(): returns the address of the fee token
// 3. _getFee(): returns the fee to pay
// 4. _transferRelayFee(): transfers the required fee to Gelato's feeCollector.abi
// 5. _transferRelayFeeCapped(uint256 maxFee): transfers the fee to Gelato, IF fee < maxFee
// 6. __msgData(): returns the original msg.data without appended information
// 7. onlyGelatoRelay modifier: allows only Gelato Relay's smart contract to call the function
contract CounterRelayContext is GelatoRelayContext {
    uint256 public counter;

    event IncrementCounter(uint256 newCounterValue);

    // this function increments a counter after paying Gelato successfully using the helper methods
    function increment() external onlyGelatoRelay {
        // transfer fees to Gelato
        _transferRelayFee();

        counter++;
        emit IncrementCounter(counter);
    }
}