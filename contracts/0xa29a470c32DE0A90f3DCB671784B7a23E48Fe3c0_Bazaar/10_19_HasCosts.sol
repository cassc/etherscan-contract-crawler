// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";


contract HasCosts {
    using Address for address payable;

    /// Not enough funds for transfer; requested `requested`, but only `available` available
    error InsufficientFunds(uint requested, uint available);

    /// pre-condition: requires a certain fee being associated with the call.
    /// post-condition: if value sent is greater than the fee, the difference will be refunded.
    modifier costs(uint value) {
        if (msg.value < value) revert InsufficientFunds(value, msg.value);
        _;
        if (msg.value > value) payable(msg.sender).sendValue(msg.value - value);
    }
}