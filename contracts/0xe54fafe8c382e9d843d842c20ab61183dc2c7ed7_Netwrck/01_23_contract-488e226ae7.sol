// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*
 | \ | |    | |                   | |   
 |  \| | ___| |___      ___ __ ___| | __
 | . ` |/ _ \ __\ \ /\ / / '__/ __| |/ /
 | |\  |  __/ |_ \ V  V /| | | (__|   < 
 |_| \_|\___|\__| \_/\_/ |_|  \___|_|\_\
                                        
 * The Currency of AI
 * 
 * https://netwrck.com
 * https://Text-Generator.io
 * https://askFelix.ai
 * https://discord.gg/2rs5xWD5HQ AI APIs
 * https://discord.gg/6zQbfcyF AIs and People Socializing
 * https://twitter.com/Netwrck
*/
import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20FlashMint.sol";

contract Netwrck is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit, ERC20FlashMint {
    constructor() ERC20("Netwrck", "NETW") ERC20Permit("Netwrck") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}