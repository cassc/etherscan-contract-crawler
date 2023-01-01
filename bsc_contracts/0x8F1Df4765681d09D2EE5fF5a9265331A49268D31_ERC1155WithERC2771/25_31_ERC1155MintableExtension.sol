// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../base/ERC1155BaseInternal.sol";
import "./IERC1155MintableExtension.sol";

/**
 * @title Extension of {ERC1155} that allows other facets of the diamond to mint based on arbitrary logic.
 */
abstract contract ERC1155MintableExtension is IERC1155MintableExtension, ERC1155BaseInternal {
    /**
     * @inheritdoc IERC1155MintableExtension
     */
    function mintByFacet(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _mint(to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155MintableExtension
     */
    function mintByFacet(
        address[] calldata tos,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes[] calldata datas
    ) public virtual {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _mintBatch(tos, ids, amounts, datas);
    }
}