// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ApeCoinStakeVault contract.
 */
interface IApeCoinStakeVault {
    /**
     * @dev Emitted every time a yield harvest is done
     * @param amount Amount of tokens that was harvested
     * @param fees Amount of fees sent to the admin
     */
    event Harvested(uint256 amount, uint256 fees);

    /**
     * @dev Harvest the yield generated till now, transfer the admin the fees accumilated
     * and restake the remaining assets if meet the requirement
     */
    function harvestYield() external;

    /**
     * @dev Owner action to update fees percentage for the protocol
     * @param fees Protocol fees in basis points
     */
    function setFee(uint256 fees) external;
}