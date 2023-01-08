// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC721MintableOwnable.sol";

/**
 * @title ERC721 - Mint as owner - with meta-transactions
 * @notice Allow minting as owner via meta transactions, signed by the owner private key. (supports ERC721A)
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721MintableExtension
 * @custom:provides-interfaces IERC721MintableOwnable
 */
contract ERC721MintableOwnableERC2771 is ERC721MintableOwnable, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}