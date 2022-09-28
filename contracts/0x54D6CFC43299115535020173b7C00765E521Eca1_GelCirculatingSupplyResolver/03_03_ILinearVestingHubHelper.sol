// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC2ILinearVestingHubHelper {
    function calcTotalUnvestedTokens()
        external
        view
        returns (uint256 totalUnvestedTkn);
}