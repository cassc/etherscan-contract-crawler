//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC20.sol";

abstract contract Mintable is ERC20{

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) public virtual
    {
        _mint(account,amount);
    }
}