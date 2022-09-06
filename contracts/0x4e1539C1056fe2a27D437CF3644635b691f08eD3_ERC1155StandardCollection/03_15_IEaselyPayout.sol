// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev External interface of the EaselyPayout contract
 */
interface IEaselyPayout {
    /**
     * @dev Takes in a payable amount and splits it among the given royalties.
     * Also takes a cut of the payable amount depending on the sender and the primaryPayout address.
     * Ensures that this method never splits over 100% of the payin amount.
     */
    function splitPayable(
        address primaryPayout,
        address[] memory royalties,
        uint256[] memory bps
    ) external payable;
}