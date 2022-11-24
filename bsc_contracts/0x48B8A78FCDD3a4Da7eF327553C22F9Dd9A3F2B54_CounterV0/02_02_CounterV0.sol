// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract CounterV0 {
    using Address for address payable;

    address public immutable relayTransit;
    uint256 public counter;

    modifier onlyRelayTransit() {
        require(msg.sender == relayTransit, "OnlyRelayTransit");
        _;
    }

    constructor(address _relayTransit) {
        relayTransit = _relayTransit;
    }

    event GetBalance(uint256 balance);
    event IncrementCounter(uint256 newCounterValue);

    function increment(uint256 _fee) external onlyRelayTransit {
        payable(msg.sender).sendValue(_fee);

        counter++;

        emit IncrementCounter(counter);
    }

    function getBalance() external {
        emit GetBalance(address(this).balance);
    }
}