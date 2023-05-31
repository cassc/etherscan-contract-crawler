// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Fee Debugger interface
 */
interface IFeeDebugger is IERC165 {
    /**
     * Whether or not the message sender can override the royalty address for the given token address
     *
     * @param tokenAddress     - The token address you are looking up the royalty for
     * @param candidateAddress - The address to check. If the function returns true, this address can be used to
     *                           override the fees for the given token address.
     */
    function overrideAllowed(address tokenAddress, address candidateAddress)
        external
        view
        returns (bool);
}