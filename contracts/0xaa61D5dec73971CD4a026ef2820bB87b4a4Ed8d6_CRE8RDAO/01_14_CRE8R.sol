/*

8ΞΞΞΞ8 8ΞΞΞ8  8ΞΞΞΞ  ΞΞΞΞΞ  8ΞΞΞ8     8ΞΞΞΞ8 8ΞΞΞΞ8 8ΞΞΞ88 
8    Ξ 8   8  8      8   8  8   8     8    8 8    8 8    8 
8Ξ     8ΞΞΞ8Ξ 8ΞΞΞΞ  8ΞΞΞ8  8ΞΞΞ8Ξ    8Ξ   8 8ΞΞΞΞ8 8    8 
88     88   8 88    88   88 88   8    88   8 88   8 8    8 
88   Ξ 88   8 88    88   88 88   8    88   8 88   8 8    8 
88ΞΞΞ8 88   8 88ΞΞΞ 88ΞΞΞ88 88   8    88ΞΞΞ8 88   8 8ΞΞΞΞ8 
*/                                                           

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract CRE8RDAO is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    constructor() ERC20("CRE8R DAO ", "CRE8R") ERC20Permit("CRE8R DAO ") {
        _mint(msg.sender, 88888888 * 10 ** decimals());
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