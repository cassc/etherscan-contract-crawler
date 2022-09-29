// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";

/// @title Contains constants which may be used by an ValidateMint contract
abstract contract AValidateMint is IValidateMint {
    uint256 public constant VALIDATE_STATUS__NA = 0;
    uint256 public constant VALIDATE_STATUS__PASS = 1;
    uint256 public constant VALIDATE_STATUS__FAIL = 2;
}