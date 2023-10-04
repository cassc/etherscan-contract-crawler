/*
 
*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Mintable.sol";

contract DATEN3 is ERC20, ERC20Burnable, Ownable, Mintable {
      
    constructor()
        ERC20(unicode"DATEN3", unicode"DATEN3") 
        Mintable(880000000)
    {
        address supplyRecipient = 0x0f880aEE8cA9298fE4011817109cF114A812b8d6;
        
        _mint(supplyRecipient, 440000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x0f880aEE8cA9298fE4011817109cF114A812b8d6);
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
        if (from == address(0)) {
        }

        super._afterTokenTransfer(from, to, amount);
    }
}