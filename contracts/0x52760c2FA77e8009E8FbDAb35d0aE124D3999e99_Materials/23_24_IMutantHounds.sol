// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity 0.8.17;

/**
 * @dev Interface to the Collars contract with required functions
 */
interface IMutantHounds {

    /**
     * @dev Burn a hound for use in the Materials contract
     */

    function materialsBurn(uint256[] memory tokenIds, address burner) external;


}