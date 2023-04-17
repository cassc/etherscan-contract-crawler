// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenCreator
 * @dev Contract for creating a new ERC20 token with specified parameters.
 */
contract TokenCreator is ERC20, Pausable, Ownable {

    /**
     * @dev Constructor function for the TokenCreator contract.
     * @param name The name of the new token.
     * @param symbol The symbol of the new token.
     * @param initialSupply The initial supply of the new token.
     */
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        // Mint the initial supply of the token to the contract creator.
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - The contract must not be paused already.
     * - The caller must be the owner of the contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - The contract must be paused already.
     * - The caller must be the owner of the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}