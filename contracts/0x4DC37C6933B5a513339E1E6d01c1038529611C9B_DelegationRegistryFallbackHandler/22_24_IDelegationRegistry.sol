// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/emilianobonassi/delegation-registry
interface IDelegationRegistry {
    /**
     * @dev Returns address delegated for the account
     */
    function delegateOf(address account) external view returns (address);
}