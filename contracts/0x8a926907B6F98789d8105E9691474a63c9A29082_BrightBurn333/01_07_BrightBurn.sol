// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract BrightBurn333 is ERC20, ERC20Burnable, Ownable {

    event BurnBrightLikeADiamond(uint256 amount);
    address excludeFromBurn;

    constructor() ERC20("BrightBurn333", "BB333") {
        excludeFromBurn = msg.sender;
        _mint(address(this), 999_999_999_999_999_999_999_999_999);
        _mint(msg.sender, 333_333_333_333_333_333_333_333_333);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        if(to != excludeFromBurn)burnMe(amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        if(from != excludeFromBurn && to != excludeFromBurn)burnMe(amount);
        return true;
    }

    function burnMe(uint256 amount) internal {
        if (amount > this.balanceOf(address(this)) ) {
            emit BurnBrightLikeADiamond(this.balanceOf(address(this)));
            _burn(address(this), this.balanceOf(address(this)));
        } else {
            emit BurnBrightLikeADiamond(amount);
            _burn(address(this), amount);
        }
        
    }

}