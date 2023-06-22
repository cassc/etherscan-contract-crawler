// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IDIVAOwnershipShared {
    /**
     * @notice Function to return the current DIVA Protocol owner address.
     * @return Current owner address. On main chain, equal to the existing owner
     * during an on-going election cycle and equal to the new owner afterwards. On secondary
     * chain, equal to the address reported via Tellor oracle.
     */
    function getCurrentOwner() external view returns (address);
}