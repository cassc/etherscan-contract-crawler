// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC1155MintableOwnable.sol";

/**
 * @title ERC1155 - Mint as owner - with meta transactions
 * @notice Allow minting as owner via ERC2771 Context meta transactions (signed by the owner private key)
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC1155MintableExtension
 * @custom:provides-interfaces IERC1155MintableOwnable
 */
contract ERC1155MintableOwnableERC2771 is ERC1155MintableOwnable, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}