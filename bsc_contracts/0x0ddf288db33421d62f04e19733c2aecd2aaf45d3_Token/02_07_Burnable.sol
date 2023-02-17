//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC20.sol";

abstract contract Burnable is ERC20{
    
    function _burn(address account, uint256 amount) internal virtual {
        
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function burn(address account, uint256 amount) public virtual
    {
        _burn(account,amount);
    }
}