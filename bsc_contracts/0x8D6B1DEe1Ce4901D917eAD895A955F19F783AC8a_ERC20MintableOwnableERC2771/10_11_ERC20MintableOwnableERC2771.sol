// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC20MintableOwnable.sol";

/**
 * @title ERC20 - Mint as owner - with meta-transactions
 * @notice Allow minting as owner via meta transactions, signed by the owner private key.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:required-dependencies IERC20MintableExtension
 * @custom:provides-interfaces IERC20MintableOwnable
 */
contract ERC20MintableOwnableERC2771 is ERC20MintableOwnable, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}