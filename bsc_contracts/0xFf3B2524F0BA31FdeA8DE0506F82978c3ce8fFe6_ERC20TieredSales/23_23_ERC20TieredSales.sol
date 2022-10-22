// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../security/ReentrancyGuard.sol";
import "../../../../introspection/ERC165Storage.sol";
import "../../../../finance/sales/TieredSales.sol";
import "../../extensions/mintable/IERC20MintableExtension.sol";
import "../../extensions/supply/ERC20SupplyStorage.sol";
import "../../extensions/supply/ERC20SupplyInternal.sol";

/**
 * @title ERC20 - Tiered Sales
 * @notice Sales mechanism for ERC20 tokens with multiple tiered pricing, allowlist and allocation plans.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:required-dependencies IERC20MintableExtension IERC20SupplyExtension
 * @custom:provides-interfaces ITieredSales
 */
contract ERC20TieredSales is ReentrancyGuard, TieredSales, ERC20BaseInternal, ERC20SupplyInternal {
    using ERC165Storage for ERC165Storage.Layout;
    using ERC20SupplyStorage for ERC20SupplyStorage.Layout;

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable virtual nonReentrant {
        super._executeSale(tierId, count, maxAllowance, proof);

        IERC20MintableExtension(address(this)).mintByFacet(_msgSender(), count);
    }

    function _remainingSupply(uint256) internal view virtual override returns (uint256) {
        uint256 remainingSupply = ERC20SupplyStorage.layout().maxSupply - _totalSupply();

        return remainingSupply;
    }
}