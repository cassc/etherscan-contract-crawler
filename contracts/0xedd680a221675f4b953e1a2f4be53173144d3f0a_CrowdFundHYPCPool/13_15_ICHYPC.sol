// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice Interface for the CHYPC.sol contract.
interface ICHYPC is IERC721 {
    /**
     * Accesses the assignment function of c_HyPC so the swap can remove 
     * the assignment data when a token is redeemed or swapped.
     */
    /// @notice Assigns a string to the given c_HyPC token.
    function assign(
        uint256 tokenId,
        string memory data
    ) external;

    /// @notice Returns the assigned string for this token.
    function getAssignment(
        uint256 tokenId
    ) external view  returns (string memory);
}