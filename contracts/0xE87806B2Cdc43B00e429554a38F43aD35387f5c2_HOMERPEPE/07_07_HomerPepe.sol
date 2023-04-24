// SPDX-License-Identifier: Apache-2.0

// https://twitter.com/homerpepecoin

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HOMERPEPE is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Homer Pepe", "HOMER") {
        _mint(msg.sender, 69000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal 
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}