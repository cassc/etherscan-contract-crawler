// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";

contract METAETH is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("META ETH", "$METH") ERC20Permit("META ETH") {
        _mint(msg.sender, 850000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}