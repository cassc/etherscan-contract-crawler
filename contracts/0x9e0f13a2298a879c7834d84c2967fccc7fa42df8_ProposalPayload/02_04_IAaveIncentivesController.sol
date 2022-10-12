// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

// relevant function from https://etherscan.io/address/0xd9ed413bcf58c266f95fe6ba63b13cf79299ce31#code

interface IAaveIncentivesController {
    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);
}