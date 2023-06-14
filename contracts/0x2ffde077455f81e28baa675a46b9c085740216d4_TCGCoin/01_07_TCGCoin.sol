// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TCGCoin is Ownable, ERC20Capped {
    uint256 public constant CAP_AMOUNT = 1e8 * 1e18;

    constructor() ERC20("TCGCoin", "TCGC") ERC20Capped(CAP_AMOUNT) {}

    function mint(address to, uint256 amount) external onlyOwner {
        ERC20Capped._mint(to, amount);
    }
}