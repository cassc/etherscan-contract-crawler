// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library ERC20Utils {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Some tokens may use an internal fee and reduce the absolute amount that was deposited.
     * This method calculates that fee and returns the real amount of deposited tokens.
     */
    function strictTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint256 finalValue) {
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, value);
        finalValue = token.balanceOf(to) - balanceBefore;
    }
}