// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./base/ERC20Base.sol";

import "./extensions/supply/ERC20SupplyExtension.sol";
import "./extensions/mintable/ERC20MintableExtension.sol";

/**
 * @title ERC20 - Standard
 * @notice Standard EIP-20 token with mintable and max supply capability.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:provides-interfaces IERC20 IERC20Base IERC20SupplyExtension IERC20MintableExtension
 */
contract ERC20 is ERC20Base, ERC20SupplyExtension, ERC20MintableExtension {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20BaseInternal, ERC20SupplyExtension) {
        super._beforeTokenTransfer(from, to, amount);
    }
}