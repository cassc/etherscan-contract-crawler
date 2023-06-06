// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * Common token functionality extracted from BitClusterNordToken. Includes:
 *  - ability for holders to burn (destroy) their tokens;
 *  - ability for contract owner to mint new tokens;
 *  - ability for contract owner to stop all token transfers;
 *
 * This is a simplified version of ERC20PresetMinterPauser from OpenZeppelin contracts.
 */
contract ERC20PresetOwnablePausable is Context, Ownable, ERC20Burnable, ERC20Pausable {

    /**
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * Creates `amount` new tokens for `to`.
     * See {ERC20-_mint}.
     */
    function mint(address to, uint256 amount) external virtual onlyOwner {
        _mint(to, amount);
    }

    /**
     * Pauses all token transfers.
     * See {ERC20Pausable} and {Pausable-_pause}.
     */
    function pause() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * Unpauses all token transfers.
     * See {ERC20Pausable} and {Pausable-_unpause}.
     */
    function unpause() external virtual onlyOwner whenPaused {
        _unpause();
    }

    /**
     * Overrides ERC20._beforeTokenTransfer to include the pause behavior.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

}