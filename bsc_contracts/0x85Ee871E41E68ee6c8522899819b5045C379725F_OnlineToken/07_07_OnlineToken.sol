// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract OnlineToken is Ownable, ERC20Burnable {
    constructor(address wallet, uint256 totalSupply) Ownable() ERC20("Online","Online") {
        require(wallet != address(0), "Invalid address");
        _mint(wallet, totalSupply);
        transferOwnership(wallet);
    }
}