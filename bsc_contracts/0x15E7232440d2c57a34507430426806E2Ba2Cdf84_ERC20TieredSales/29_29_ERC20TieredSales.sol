// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../security/ReentrancyGuard.sol";
import "../../../../introspection/ERC165Storage.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../../../finance/sales/TieredSales.sol";
import "../../../../finance/sales/ITieredSalesRoleBased.sol";
import "../../extensions/mintable/IERC20MintableExtension.sol";
import "../../extensions/supply/ERC20SupplyStorage.sol";
import "../../extensions/supply/ERC20SupplyInternal.sol";
import "../metadata/ERC20MetadataStorage.sol";

/**
 * @title ERC20 - Tiered Sales
 * @notice Sales mechanism for ERC20 tokens with multiple tiered pricing, allowlist and allocation plans.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:required-dependencies IERC20MintableExtension IERC20SupplyExtension
 * @custom:provides-interfaces ITieredSales ITieredSalesRoleBased
 */
contract ERC20TieredSales is
    ITieredSalesRoleBased,
    ReentrancyGuard,
    TieredSales,
    ERC20BaseInternal,
    ERC20SupplyInternal,
    AccessControlInternal
{
    using ERC165Storage for ERC165Storage.Layout;
    using ERC20SupplyStorage for ERC20SupplyStorage.Layout;
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable virtual nonReentrant {
        super._executeSale(tierId, count, maxAllowance, proof);

        IERC20MintableExtension(address(this)).mintByFacet(_msgSender(), count);
    }

    function mintByTierByRole(
        address minter,
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable virtual nonReentrant onlyRole(MERCHANT_ROLE) {
        super._executeSaleSkipPayment(minter, tierId, count, maxAllowance, proof);

        IERC20MintableExtension(address(this)).mintByFacet(minter, count);
    }

    function _processPayment(
        uint256 tierId,
        address minter,
        address currency,
        uint256 count,
        uint256 price
    ) internal virtual override {
        tierId;

        if (price > 0) {
            if (currency == address(0)) {
                require(
                    (price * count) <= msg.value * (10**ERC20MetadataStorage.layout().decimals),
                    "INSUFFICIENT_AMOUNT"
                );
            } else {
                uint256 amountTotal = (price * count) / (10**ERC20MetadataStorage.layout().decimals);
                require(amountTotal > 0, "INCORRECT_COUNT");
                IERC20(currency).transferFrom(minter, address(this), amountTotal);
            }
        }
    }

    function _remainingSupply(uint256) internal view virtual override returns (uint256) {
        uint256 remainingSupply = ERC20SupplyStorage.layout().maxSupply - _totalSupply();

        return remainingSupply;
    }
}