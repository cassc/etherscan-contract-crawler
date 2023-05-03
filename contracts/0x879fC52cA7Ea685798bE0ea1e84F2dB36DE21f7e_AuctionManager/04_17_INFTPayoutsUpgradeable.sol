// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the Multiple NFT Payouts Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 */
interface INFTPayoutsUpgradeable is IERC165Upgradeable {
    function creator(uint256 tokenId) external view returns (address);

    function payoutCount(
        uint256 tokenId,
        bool isPayout
    ) external view returns (uint256);

    function payoutInfo(
        uint256 tokenId,
        uint256 salePrice,
        bool isPayout
    )
        external
        view
        returns (address[] memory receivers, uint256[] memory payoutAmounts);
}