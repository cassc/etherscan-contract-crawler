// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "./Monetary.sol";


abstract contract HasCosts {
    using Address for address payable;
    using Monetary for Monetary.Crypto;

    /// Not enough funds for transfer; requested `requested`, but only `available` available
    error InsufficientFunds(Monetary.Crypto requested, Monetary.Crypto available);

    /// pre-condition: requires a certain fee being associated with the call.
    /// post-condition: if value sent is greater than the fee, the difference will be refunded.
    modifier costs(Monetary.Crypto memory cost) {
        Monetary.Crypto memory crypto = Monetary.Native(msg.value);
        if (cost.isGreaterThan(crypto)) revert InsufficientFunds(cost, crypto);
        _;
        if (crypto.isGreaterThan(cost)) crypto.minus(cost).transferTo(msg.sender);
    }
}