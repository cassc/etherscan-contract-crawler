// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../security/ReentrancyGuard.sol";
import "../../../../introspection/ERC165Storage.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../../../finance/sales/TieredSales.sol";
import "../../../../finance/sales/ITieredSalesRoleBased.sol";
import "../../extensions/mintable/IERC721MintableExtension.sol";
import "../../extensions/supply/ERC721SupplyStorage.sol";
import "../../extensions/supply/ERC721SupplyInternal.sol";

/**
 * @title ERC721 - Tiered Sales
 * @notice Sales mechanism for ERC721 NFTs with multiple tiered pricing, allowlist and allocation plans.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721MintableExtension IERC721SupplyExtension
 * @custom:provides-interfaces ITieredSales ITieredSalesRoleBased
 */
contract ERC721TieredSales is
    ITieredSalesRoleBased,
    ReentrancyGuard,
    TieredSales,
    ERC721SupplyInternal,
    AccessControlInternal
{
    using ERC165Storage for ERC165Storage.Layout;
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;

    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable virtual nonReentrant {
        super._executeSale(tierId, count, maxAllowance, proof);

        IERC721MintableExtension(address(this)).mintByFacet(_msgSender(), count);
    }

    function mintByTierByRole(
        address minter,
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable virtual nonReentrant onlyRole(MERCHANT_ROLE) {
        super._executeSalePrivileged(minter, tierId, count, maxAllowance, proof);

        IERC721MintableExtension(address(this)).mintByFacet(minter, count);
    }

    function _remainingSupply(uint256) internal view virtual override returns (uint256) {
        uint256 remainingSupply = ERC721SupplyStorage.layout().maxSupply - _totalSupply();

        return remainingSupply;
    }
}