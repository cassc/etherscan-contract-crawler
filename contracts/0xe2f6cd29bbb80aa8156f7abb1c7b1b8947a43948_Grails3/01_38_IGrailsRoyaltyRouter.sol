// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Grails Royalty Router
 * @author PROOF
 * @notice A centralized contract to compute and route secondary royalties in
 * loose accordance with ERC2981.
 */
interface IGrailsRoyaltyRouter is IERC165 {
    /**
     * @notice Computes the creator fee and royalty address for a secondary
     * sale of a given Grail (defined by season and grail ID).
     * @dev This will be consumed Grail contracts - more specifically in their
     * ERC2981 implementation.
     */
    function royaltyInfo(
        uint256 season,
        uint256 grailId,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256);
}