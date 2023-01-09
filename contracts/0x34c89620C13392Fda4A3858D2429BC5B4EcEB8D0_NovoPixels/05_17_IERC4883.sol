// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title EIP-4883 Non-Fungible Token Standard
/// Based on https://eips.ethereum.org/EIPS/eip-4883
interface IERC4883 is IERC165 {
    /**
     * @dev Generates the SVG image of `id`
     *
     * Requirements:
     *
     * - `id` must exist
     * - must return the SVG body for the specified token `id`
     * - must either be an empty string or a valid SVG element(s)
     */
    function renderTokenById(uint256 id) external view returns (string memory);
}