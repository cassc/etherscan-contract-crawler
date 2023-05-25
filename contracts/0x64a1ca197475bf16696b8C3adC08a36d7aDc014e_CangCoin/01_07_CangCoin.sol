// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

////CangCoin.sol

contract CangCoin is ERC20,Ownable, ERC20Burnable{
    constructor(address _to) ERC20("Cang Coin", "CC") {
        _mint(_to, 20000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}