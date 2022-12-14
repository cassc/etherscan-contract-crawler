// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC1155MintableRoleBased.sol";

/**
 * @title ERC1155 - Mint as role - with meta transactions
 * @notice Allow minting for grantees of MINTER_ROLE with meta-transactions supported via ERC2771.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC1155MintableExtension
 * @custom:provides-interfaces IERC1155MintableRoleBased
 */
contract ERC1155MintableRoleBasedERC2771 is ERC1155MintableRoleBased, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}