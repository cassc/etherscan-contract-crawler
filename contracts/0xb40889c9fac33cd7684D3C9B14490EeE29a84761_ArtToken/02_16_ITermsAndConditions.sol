// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for exposing an URI to the terms and conditions.
 *
 * This makes it possible to specify the current terms and conditions on-chain. 
 * Ideally, the URI points to an IPFS address or some other immutable source.
 */
interface ITermsAndConditions is IERC165 {

    /**
     * Returns the URI to the current terms and conditions
     */
    function termsAndConditionsURI() external view returns (string memory);

}