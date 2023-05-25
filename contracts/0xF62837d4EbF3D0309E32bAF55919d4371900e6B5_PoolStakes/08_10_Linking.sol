// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This file contains fake libs just for static linking.
 * These fake libs' code is assumed to never run.
 * On compilation of dependant contracts, instead of fake libs addresses,
 * indicate addresses of deployed real contracts (or accounts).
 */

/// @dev Address of the ZKPToken contract ('../ZKPToken.sol') instance
library TokenAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

/// @dev Address of the VestingPools ('../VestingPools.sol') instance
library VestingPoolsAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}

/// @dev Address of the PoolStakes._defaultOwner
// (NB: if it's not a multisig, transfer ownership to a Multisig contract)
library DefaultOwnerAddress {
    function neverCallIt() external pure {
        revert("FAKE");
    }
}