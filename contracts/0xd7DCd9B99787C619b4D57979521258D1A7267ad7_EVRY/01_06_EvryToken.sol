//contracts/EVRY.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract EVRY is ERC20Burnable {
    uint256 public constant INITIAL_SUPPLY = 1000 * 10**(6 + 18); // 1000M tokens
    constructor() ERC20("EvrynetToken", "EVRY") {
        // @dev Mints `initialSupply` amount of token and transfers them to `owner`
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}