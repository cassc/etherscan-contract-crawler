// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IAdventureERC721Initializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include Adventure ERC721 functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IAdventureERC721Initializer is IERC165 {

    /**
     * @notice Initializes parameters of {AdventureERC721} contracts
     */
    function initializeAdventureERC721(uint256 maxSimultaneousQuests_) external;
}