// contracts/SBFMDC.sol
// SPDX-License-Identifier: MIT

/*
SBFMDC - Metropolitan Detention Center Operations Fund

Website: https://www.sbfmdc.com/
Twitter: https://twitter.com/SBFMDC
*/

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SBFMDC is ERC20, ERC20Capped, ERC20Burnable, ERC20Permit, Ownable {
    constructor(uint256 cap) ERC20("SBFMDC", "SBFMDC") ERC20Capped(cap * (10 ** decimals())) ERC20Permit("SBFMDC") {
        _mint(msg.sender, 8000000000 * 10 ** decimals());
    }

    // These functions have overrides added due to inheritence. 
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20)
    {
        super._burn(account, amount);
    }

    function renounceOwnership() public override onlyOwner {

        _transferOwnership(address(0));
    }

}