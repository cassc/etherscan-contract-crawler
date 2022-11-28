// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC1155TieredSales.sol";

/**
 * @dev Tiered Sales facet for ERC1155 with meta-transactions support via ERC2771
 */
contract ERC1155TieredSalesERC2771 is ERC1155TieredSales, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}