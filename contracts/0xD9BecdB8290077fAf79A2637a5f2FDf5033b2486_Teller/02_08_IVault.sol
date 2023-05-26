// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/**
 * @title Vault Interface
 */
interface IVault {
    /**
     * @dev External function to get vidya rate.
     */
    function vidyaRate() external view returns (uint256);

    /**
     * @dev External function to get total priority.
     */
    function totalPriority() external view returns (uint256);

    /**
     * @dev External function to get teller priority.
     * @param tellerId Teller Id
     */
    function tellerPriority(address tellerId) external view returns (uint256);

    /**
     * @dev External function to add the teller. This function can be called by only owner.
     * @param teller Address of teller
     * @param priority Priority of teller
     */
    function addTeller(address teller, uint256 priority) external;

    /**
     * @dev External function to change the priority of teller. This function can be called by only owner.
     * @param teller Address of teller
     * @param newPriority New priority of teller
     */
    function changePriority(address teller, uint256 newPriority) external;

    /**
     * @dev External function to pay the Vidya token to investors. This function can be called by only teller.
     * @param provider Address of provider
     * @param providerTimeWeight Weight time of provider
     * @param totalWeight Sum of provider weight
     */
    function payProvider(
        address provider,
        uint256 providerTimeWeight,
        uint256 totalWeight
    ) external;

    /**
     * @dev External function to calculate the Vidya Rate.
     */
    function calculateRateExternal() external;
}