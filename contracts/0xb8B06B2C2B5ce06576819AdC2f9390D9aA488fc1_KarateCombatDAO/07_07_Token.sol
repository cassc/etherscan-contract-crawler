/*
// Karate Combat
// $KARATE is the utility token for our new Karate Combat App for iOS.
// Website: https://www.karate.com/whitepaper
// Telegram: https://t.me/karateportal
// Twitter: https://www.karate.com/whitepaper
 __  __ _______ ______ _______ _______ _______ 
|  |/  |   _   |   __ \   _   |_     _|    ___|
|     <|       |      <       | |   | |    ___|
|__|\__|___|___|___|__|___|___| |___| |_______|
                                               
*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 

contract KarateCombatDAO is ERC20, ERC20Burnable, Ownable {
      
    constructor()
        ERC20("Karate Combat DAO", "KARATE") 
    {
        address supplyRecipient = 0xE5DE59E3606a37405D1e65E6eEfC4Fe2820B240b;
        
        _mint(supplyRecipient, 100000000000 * (10 ** decimals()));
        _transferOwnership(0xE5DE59E3606a37405D1e65E6eEfC4Fe2820B240b);
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