// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../introspection/ERC165Storage.sol";
import "../../../../security/ReentrancyGuard.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../../../finance/sales/TieredSales.sol";
import "../../extensions/mintable/IERC1155MintableExtension.sol";
import "../../extensions/supply/ERC1155SupplyStorage.sol";
import "../../extensions/supply/IERC1155SupplyExtension.sol";
import "./ERC1155TieredSalesStorage.sol";
import "./IERC1155TieredSales.sol";

/**
 * @title ERC1155 - Tiered Sales
 * @notice Sales mechanism for ERC1155 NFTs with multiple tiered pricing, allowlist and allocation plans.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC1155MintableExtension
 * @custom:provides-interfaces ITieredSales IERC1155TieredSales ITieredSalesRoleBased
 */
contract ERC1155TieredSales is IERC1155TieredSales, ReentrancyGuard, TieredSales, AccessControlInternal {
    using ERC165Storage for ERC165Storage.Layout;
    using ERC1155TieredSalesStorage for ERC1155TieredSalesStorage.Layout;
    using ERC1155SupplyStorage for ERC1155SupplyStorage.Layout;

    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable virtual nonReentrant {
        super._executeSale(tierId, count, maxAllowance, proof);

        IERC1155MintableExtension(address(this)).mintByFacet(
            _msgSender(),
            ERC1155TieredSalesStorage.layout().tierToTokenId[tierId],
            count,
            ""
        );
    }

    function mintByTierByRole(
        address minter,
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable virtual nonReentrant onlyRole(MERCHANT_ROLE) {
        super._executeSaleSkipPayment(minter, tierId, count, maxAllowance, proof);

        IERC1155MintableExtension(address(this)).mintByFacet(
            minter,
            ERC1155TieredSalesStorage.layout().tierToTokenId[tierId],
            count,
            ""
        );
    }

    function tierToTokenId(uint256 tierId) external view virtual returns (uint256) {
        return ERC1155TieredSalesStorage.layout().tierToTokenId[tierId];
    }

    function tierToTokenId(uint256[] calldata tierIds) external view virtual returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](tierIds.length);

        for (uint256 i = 0; i < tierIds.length; i++) {
            tokenIds[i] = ERC1155TieredSalesStorage.layout().tierToTokenId[tierIds[i]];
        }

        return tokenIds;
    }

    function _remainingSupply(uint256 tierId) internal view virtual override returns (uint256) {
        if (!ERC165Storage.layout().supportedInterfaces[type(IERC1155SupplyExtension).interfaceId]) {
            return type(uint256).max;
        }

        uint256 tokenId = ERC1155TieredSalesStorage.layout().tierToTokenId[tierId];

        uint256 remainingSupply = ERC1155SupplyStorage.layout().maxSupply[tokenId] -
            ERC1155SupplyStorage.layout().totalSupply[tokenId];

        return remainingSupply;
    }
}