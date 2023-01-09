// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";

abstract contract ERC20Burnable is Context, ERC20 {

    using SafeMath for uint256;

    uint256 public totalBurned;

    function burn(uint256 amount) public virtual {
        totalBurned = totalBurned.add(amount);
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        totalBurned = totalBurned.add(amount);
        _burn(account, amount);
    }
}