// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    GelatoRelayFeeCollector
} from "@gelatonetwork/relay-context/contracts/GelatoRelayFeeCollector.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// Inheriting GelatoRelayFeeCollector gives access to:
// 1. _getFeeCollector(): returns the address of Gelato's feeCollector
// 2. __msgData(): returns the original msg.data without feeCollector appended
// 3. onlyGelatoRelay modifier: allows only Gelato Relay's smart contract to call the function
contract CounterFeeCollector is GelatoRelayFeeCollector {
    using Address for address payable;

    uint256 public counter;

    event GetBalance(uint256 balance);
    event IncrementCounter(uint256 newCounterValue);

    // `increment` is the target function to call
    // this function increments the state variable `counter` by 1
    function increment(uint256 _fee) external onlyGelatoRelay {
        // Payment to Gelato
        // NOTE: be very careful here!
        // if you do not use the onlyGelatoRelay modifier,
        // anyone could encode themselves as the fee collector
        // in the low-level data and drain tokens from this contract.
        payable(_getFeeCollector()).sendValue(_fee);

        counter++;

        emit IncrementCounter(counter);
    }

    // `increment` is the target function to call
    // this function increments the state variable `counter` by 1
    function increment() external onlyGelatoRelay {
        // Payment to Gelato
        // NOTE: be very careful here!
        // if you do not use the onlyGelatoRelay modifier,
        // anyone could encode themselves as the fee collector
        // in the low-level data and drain tokens from this contract.
        payable(_getFeeCollector()).sendValue(100);

        counter++;

        emit IncrementCounter(counter);
    }

    function getBalance() external {
        emit GetBalance(address(this).balance);
    }
}