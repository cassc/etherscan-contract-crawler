//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/**
 * A simple specification for an ERC-20 claim contract, that allows for parent 
 * DAOs that have created a new ERC-20 token voting subDAO to allocate a certain
 * amount of those tokens as claimable by the parent DAO token holders or signers.
 */
interface IERC20Claim {

    /**
     * Allows parent token holders to claim tokens allocated by a 
     * subDAO during its creation.
     *
     * @param claimer address which is being claimed for, allowing any address to
     *      process a claim for any other address
     */
    function claimTokens(address claimer) external;

    /**
     * Gets an address' token claim amount.
     *
     * @param claimer address to check the claim amount of
     * @return uint256 the given address' claim amount
     */
    function getClaimAmount(address claimer) external view returns (uint256);

    /**
     * Returns unclaimed tokens after the claim deadline to the funder.
     */
    function reclaim() external;
}