// SPDX-License-Identifier: MIT
// https://github.com/Brickken/license/blob/main/README.md
pragma solidity ^0.8.0;

import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Brickken is ERC20, AccessControl, ERC20Permit, ERC20Votes {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("Brickken", "BKN") ERC20Permit("Brickken") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public onlyRole(BURNER_ROLE){
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    /**
     * @dev Mint `amount` tokens to the `to` address.
     *
     * See {ERC20-_mint}.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        super._mint(to, amount);
    }

    /**
     * @dev Hook called after each token transfer. It moves votes delegation
     * calling the `ERC20Votes` function.
     */
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        ERC20Votes._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}