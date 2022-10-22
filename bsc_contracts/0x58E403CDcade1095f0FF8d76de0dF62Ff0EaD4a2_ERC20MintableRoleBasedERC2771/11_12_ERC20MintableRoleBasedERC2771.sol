// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../metatx/ERC2771ContextInternal.sol";
import "./ERC20MintableRoleBased.sol";

/**
 * @dev Extension of {ERC20} to mint by MINTER_ROLE
 */
/**
 * @title ERC20 - Mint as role - with meta-transactions
 * @notice Allow minting for senders with MINTER_ROLE to mint new tokens with meta-transactions supported via ERC2771 (supports ERC20A).
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:required-dependencies IERC20MintableExtension
 * @custom:provides-interfaces IERC20MintableRoleBased
 */
contract ERC20MintableRoleBasedERC2771 is ERC20MintableRoleBased, ERC2771ContextInternal {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}