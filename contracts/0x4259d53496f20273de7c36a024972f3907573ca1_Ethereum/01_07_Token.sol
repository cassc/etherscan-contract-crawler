/*

#####################################
Token generated with ❤️ on 20lab.app
#####################################

*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 

contract Ethereum is ERC20, ERC20Burnable, Ownable {
      
    constructor()
        ERC20(unicode"Ethereum", unicode"ETH") 
    {
        address supplyRecipient = 0xfE7C51f74a1459eB423761DD4F12dBe0De5b3bAD;
        
        _mint(supplyRecipient, 100000000 * (10 ** decimals()));
        _transferOwnership(0xfE7C51f74a1459eB423761DD4F12dBe0De5b3bAD);
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