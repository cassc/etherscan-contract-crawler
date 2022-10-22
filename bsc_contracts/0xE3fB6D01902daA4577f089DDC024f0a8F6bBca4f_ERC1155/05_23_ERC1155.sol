// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./base/ERC1155Base.sol";
import "./extensions/supply/ERC1155SupplyExtension.sol";
import "./extensions/lockable/ERC1155LockableExtension.sol";
import "./extensions/mintable/ERC1155MintableExtension.sol";
import "./extensions/burnable/ERC1155BurnableExtension.sol";

/**
 * @title ERC1155 - Standard
 * @notice Standard EIP-1155 NFTs with core capabilities of Mintable, Burnable and Lockable.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:provides-interfaces IERC1155 IERC1155BurnableExtension IERC1155LockableExtension IERC1155MintableExtension IERC1155SupplyExtension
 */
contract ERC1155 is
    ERC1155Base,
    ERC1155SupplyExtension,
    ERC1155MintableExtension,
    ERC1155BurnableExtension,
    ERC1155LockableExtension
{
    /**
     * @notice inheritdoc IERC1155Metadata
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155BaseInternal, ERC1155SupplyInternal, ERC1155LockableInternal) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}