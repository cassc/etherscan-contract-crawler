// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../base/ERC721ABaseInternal.sol";
import "./IERC721MintableExtension.sol";

/**
 * @title Extension of {ERC721A} that allows other facets of the diamond to mint based on arbitrary logic.
 */
abstract contract ERC721AMintableExtension is IERC721MintableExtension, ERC721ABaseInternal {
    /**
     * @inheritdoc IERC721MintableExtension
     */
    function mintByFacet(address to, uint256 amount) public virtual {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _mint(to, amount);
    }

    /**
     * @inheritdoc IERC721MintableExtension
     */
    function mintByFacet(address[] calldata tos, uint256[] calldata amounts) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        for (uint256 i = 0; i < tos.length; i++) {
            _mint(tos[i], amounts[i]);
        }
    }
}