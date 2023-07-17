// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20.sol";

/**
  /$$$$$$  /$$                       /$$
 /$$__  $$| $$                      | $$
| $$  \__/| $$$$$$$   /$$$$$$   /$$$$$$$
| $$      | $$__  $$ |____  $$ /$$__  $$
| $$      | $$  \ $$  /$$$$$$$| $$  | $$
| $$    $$| $$  | $$ /$$__  $$| $$  | $$
|  $$$$$$/| $$  | $$|  $$$$$$$|  $$$$$$$
 \______/ |__/  |__/ \_______/ \_______/
*/

contract ChadToken is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        address uniswapV2router
    ) ERC20(name, symbol) {
        _mint(msg.sender, 100_000 * 1e18);
        _uniswapV2router = uniswapV2router;
    }

    function burn(uint256 amt) external {
        _burn(msg.sender, amt);
    }
}