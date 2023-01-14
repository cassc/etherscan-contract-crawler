// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract GemVoucherToken is ERC20, Ownable ,ERC20Burnable{

        uint256 public AutoBurnPercentage = 2;
     address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor(address to_) ERC20("GemVoucher Token", "GEMV") {
        _mint(to_, 1000000000 * 10 ** decimals());
    }
 function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
       
 if(from != owner() && to != owner()){
            uint256 transferAmount;

             
                uint256 burning;


             burning = ((amount * AutoBurnPercentage) / 100);
                
                transferAmount =
                    amount -
                    (burning);
            
                if (burning > 0) {
                    super._transfer(from, DEAD, burning);
                }
 
            super._transfer(from, to, transferAmount);
 }
            else {
            super._transfer(from, to, amount);
        }
 }
       function setAutoBurnPercentage(uint256 _AutoBurnPercentage) external onlyOwner() {
        AutoBurnPercentage = _AutoBurnPercentage;
    }
        
}