// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBaseOracle {
    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view returns (uint256);
}