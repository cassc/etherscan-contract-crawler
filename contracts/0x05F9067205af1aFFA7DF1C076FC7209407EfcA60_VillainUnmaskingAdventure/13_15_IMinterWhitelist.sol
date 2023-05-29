// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Required interface to determine if a minter is whitelisted
 */
interface IMinterWhitelist {
    /**
     * @notice Determines if an address is a whitelisted minter
     */
    function whitelistedMinters(address account) external view returns (bool);
}