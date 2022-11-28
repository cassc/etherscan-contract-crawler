// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC721TieredSales.sol";

/**
 * @title ERC721 - Tiered Sales - with meta-transactions
 * @notice Sales mechanism for ERC721 NFTs with ERC2771 meta-transactions support (e.g. credit card minting).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721MintableExtension
 * @custom:provides-interfaces ITieredSales
 */
contract ERC721TieredSalesERC2771 is ERC721TieredSales, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}