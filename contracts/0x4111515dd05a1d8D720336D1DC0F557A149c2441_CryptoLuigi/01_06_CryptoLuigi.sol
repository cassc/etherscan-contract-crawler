// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CryptoLuigi is ERC20Burnable
{
    //Constructor
    constructor() ERC20("Crypto Luigi", "BROKE")
    {
        _mint(msg.sender, 1000000000 ether);
    }
}