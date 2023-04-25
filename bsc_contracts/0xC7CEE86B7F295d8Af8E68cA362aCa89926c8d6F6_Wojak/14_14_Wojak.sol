// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Wojak is ReentrancyGuard, ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("WojakBNB", "WojakBNB") ERC20Permit("WojakBNB") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }

    /// @dev Override the _transfer() function to perform the necessary burn functions:

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) nonReentrant {
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

        uint256 burnAmount = amount / 100;
        super._burn(from, burnAmount); // Burns 1%.
        super._transfer(from, to, amount - burnAmount); // Transfers the remainder to the recipient.
    }
}