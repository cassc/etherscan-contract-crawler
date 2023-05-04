// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TheChickenMan is ERC20, ERC20Burnable, Ownable {
    uint256 private constant INITIAL_SUPPLY = 69000000000 * 10**18;

    constructor() ERC20("Gus Fring", "GUS") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}