// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./base/ERC1155BaseERC2771.sol";
import "./extensions/supply/ERC1155SupplyExtension.sol";
import "./extensions/lockable/ERC1155LockableExtension.sol";
import "./extensions/mintable/ERC1155MintableExtension.sol";
import "./extensions/burnable/ERC1155BurnableExtension.sol";
import "./extensions/royalty/ERC1155RoyaltyEnforcementExtension.sol";

/**
 * @title ERC1155 - with meta-transactions
 * @notice Standard EIP-1155 with ability to accept meta transactions (mainly transfer or burn methods).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:provides-interfaces IERC1155 IERC1155SupplyExtension IERC1155MintableExtension IERC1155BurnableExtension IERC1155LockableExtension IRoyaltyEnforcement
 */
contract ERC1155WithERC2771 is
    ERC1155BaseERC2771,
    ERC1155SupplyExtension,
    ERC1155MintableExtension,
    ERC1155BurnableExtension,
    ERC1155LockableExtension,
    ERC1155RoyaltyEnforcementExtension
{
    function _msgSender() internal view virtual override(Context, ERC1155BaseERC2771) returns (address) {
        return ERC1155BaseERC2771._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC1155BaseERC2771) returns (bytes calldata) {
        return ERC1155BaseERC2771._msgData();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155BaseInternal, ERC1155SupplyInternal, ERC1155LockableInternal) {
        ERC1155BaseInternal._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC1155Base, ERC1155RoyaltyEnforcementExtension)
    {
        ERC1155RoyaltyEnforcementExtension.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override(ERC1155Base, ERC1155RoyaltyEnforcementExtension) {
        ERC1155RoyaltyEnforcementExtension.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override(ERC1155Base, ERC1155RoyaltyEnforcementExtension) {
        ERC1155RoyaltyEnforcementExtension.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}