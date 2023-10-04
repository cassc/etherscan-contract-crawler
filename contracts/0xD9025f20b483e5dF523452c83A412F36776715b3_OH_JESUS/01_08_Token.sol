/*
verified
*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Mintable.sol";

contract OH_JESUS is ERC20, ERC20Burnable, Ownable, Mintable {
      
    constructor()
        ERC20(unicode"OH JESUS", unicode"OHJ") 
        Mintable(9900000000)
    {
        address supplyRecipient = 0xC2BF4C9246da911db847934C109271c23A1a5e7a;
        
        _mint(supplyRecipient, 3300000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xC2BF4C9246da911db847934C109271c23A1a5e7a);
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