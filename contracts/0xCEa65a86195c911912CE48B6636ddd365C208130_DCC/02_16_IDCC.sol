// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ITraitBits.sol";

interface IDCC is ITraitBits {
    error ExceedsLimit();
    error InvalidIndex();
    error InvalidTokenId();
    error AlreadyRevealed();
    error ReduceAttributesSize();
    error ForbidMemoizationBeforeReveal();
}