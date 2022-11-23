// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

interface IPermitResolver {
    /**
     * @dev Converts specified permit into allowance for the caller.
     */
    function resolvePermit(
        address token,
        address from,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) external;
}