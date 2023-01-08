// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC1155TieredSales.sol";

/**
 * @title ERC1155 - Tiered Sales - with meta-transactions
 * @notice Sales mechanism for ERC1155 NFTs with ERC2771 meta-transactions support (e.g. credit card minting).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC1155MintableExtension
 * @custom:provides-interfaces ITieredSales IERC1155TieredSales ITieredSalesRoleBased
 */
contract ERC1155TieredSalesERC2771 is ERC1155TieredSales, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}