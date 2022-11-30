// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC20Wrapper {
    /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
    function getUnderlyingToken(uint256 id) external view returns (address);
}