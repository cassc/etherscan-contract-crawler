// SPDX-License-Identifier: MIT
/* 
                                                                       
 _____   ______  _____   ______       ___     _____    _____   _     _ 
(_____) (______)(_____) (______)    _(___)_  (_____)  (_____) (_)   (_)
(_)__(_)(_)__   (_)__(_)(_)__      (_)   (_)(_)___(_)(_)___   (_)___(_)
(_____) (____)  (_____) (____)     (_)    _ (_______)  (___)_ (_______)
(_)     (_)____ (_)     (_)____    (_)___(_)(_)   (_)  ____(_)(_)   (_)
(_)     (______)(_)     (______)     (___)  (_)   (_) (_____) (_)   (_)
                                                                       
  website: pepecash.wtf                                                                      
  https://twitter.com/PepeCashwtf
  t.me/Pepecashwtf

*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeCash is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable {
    constructor() ERC20("Pepe Cash", "PCASH") ERC20Permit("Pepe Cash") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}