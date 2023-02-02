// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LegendToken
 * @dev ERC20 implementation of the LEGEND utility token within the LEVERADE platform. The token is burnable, and the
 * owner can pause transfers/burns as part of an emergency response.
 * @custom:security-contact [email protected]
 */
contract LegendToken is ERC20, ERC20Burnable, Pausable, Ownable {
    /**
     * @dev Initialize contract with a fixed supply of 1,000,000,000 tokens
     */
    constructor() ERC20("Legend", "LEGEND") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    /**
     * @dev Pause token transfers (owner-only)
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Resume token transfers (owner-only)
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Hook that is called before any transfer of tokens to check that contract isn't paused
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}