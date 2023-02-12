// SPDX-License-Identifier: MIT
// Transfer fee and burn % on transfer added by github.com/Najibmansour

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ERC20WithFee is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Elemento Dragons", "ED") {
        mint(_msgSender(), 1000000000* (10 ** 18));
    }

    address public feeAddress = 0x79d78C551A0db585264405f76Bf90E07B9356479;
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

        function transfer(address to, uint256 amount) public override returns(bool){
        
        address owner = _msgSender();
        uint256 fee =  amount * 10 / 100;
        uint256 toBeBurnt =  amount / 100;
        
        _transfer(owner, to, amount - fee - toBeBurnt);
        // 10% will go to feeAddress
        _transfer(owner, feeAddress, fee);
        // 1% will be burnt from the amount sent 
        _burn(owner, toBeBurnt);

        return true;
    }
}