// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IAavePool {
    /// @dev Returns the normalized income of the reserve given the address of the underlying asset of the reserve
    function getReserveNormalizedIncome(address)
        external
        view
        returns (uint256);
}