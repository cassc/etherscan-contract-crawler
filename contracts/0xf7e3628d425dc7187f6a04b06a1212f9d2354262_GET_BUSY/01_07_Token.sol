/*
Be busy with your decentralized life.
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 

contract GET_BUSY is ERC20, ERC20Burnable, Ownable {
      
    constructor()
        ERC20(unicode"GET BUSY", unicode"BUSY") 
    {
        address supplyRecipient = 0xD01b3D72065Ed9E0da84f0775Ff63055C9DB82f5;
        
        _mint(supplyRecipient, 50000000000 * (10 ** decimals()));
        _transferOwnership(0xD01b3D72065Ed9E0da84f0775Ff63055C9DB82f5);
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