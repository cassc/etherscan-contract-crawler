/*
Marvin Dreams inc 2023.
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 

contract Marvin is ERC20, ERC20Burnable, Ownable {
      
    constructor()
        ERC20("Marvin", "MARVIN") 
    {
        address supplyRecipient = 0x3BdAA2AdA0f49cdCB34eA9502ba4D57bcd6613F5;
        
        _mint(supplyRecipient, 100000000000 * (10 ** decimals()));
        _transferOwnership(0x3BdAA2AdA0f49cdCB34eA9502ba4D57bcd6613F5);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}