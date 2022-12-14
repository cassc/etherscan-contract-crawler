// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC20TieredSales.sol";

/**
 * @title ERC20 - Tiered Sales - with meta-transactions
 * @notice Sales mechanism for ERC20 tokens with ERC2771 meta-transactions support (e.g. credit card minting).
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:required-dependencies IERC20MintableExtension
 * @custom:provides-interfaces ITieredSales
 */
contract ERC20TieredSalesERC2771 is ERC20TieredSales, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}