// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../utils/Pausable.sol";
import "hardhat/console.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    mapping(address => bool) public whitelist;

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused or sender is whitelisted.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        
        require(
            !paused() || whitelist[from] == true,
            "ERC20Pausable: token transfer while paused"
        );
    }

    function _changeWhitelistStatus(
        address whitelisteAddress,
        bool isWhitelisted
    ) internal virtual {
        whitelist[whitelisteAddress] = isWhitelisted;
    }
}