// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC721MintableRoleBased.sol";

/**
 * @dev Extension of {ERC721} to mint by MINTER_ROLE
 */
/**
 * @title ERC721 - Mint as role - with meta-transactions
 * @notice Allow minting for senders with MINTER_ROLE to mint new tokens with meta-transactions supported via ERC2771 (supports ERC721A).
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721MintableExtension
 * @custom:provides-interfaces IERC721MintableRoleBased
 */
contract ERC721MintableRoleBasedERC2771 is ERC721MintableRoleBased, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}