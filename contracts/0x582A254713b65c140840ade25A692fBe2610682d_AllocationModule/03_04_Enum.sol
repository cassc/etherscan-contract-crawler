// SPDX-License-Identifier: LGPL-3.0-only

// Vendored from @gnosis.pm/safe-contracts v1.3.0, see:
// <https://raw.githubusercontent.com/gnosis/safe-contracts/v1.3.0/contracts/common/Enum.sol>

pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}