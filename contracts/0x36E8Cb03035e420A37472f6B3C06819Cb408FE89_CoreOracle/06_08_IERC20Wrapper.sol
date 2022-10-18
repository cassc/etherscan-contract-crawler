// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20Wrapper {
    /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
    function getUnderlyingToken(uint256 id) external view returns (address);

    /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
    function getUnderlyingRate(uint256 id) external view returns (uint256);
}