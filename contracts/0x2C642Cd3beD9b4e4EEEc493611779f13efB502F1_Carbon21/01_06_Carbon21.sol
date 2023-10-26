/* 
 *   Carbon21 Project - For real Diamond Hands
 *
 *   Learn more: https://carbon21.io
 */


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Carbon21 is ERC20, ERC20Burnable {
    uint256 public originalSupply;

    event Burn(address indexed burner, uint256 amount);

    constructor() ERC20("Carbon21", "C21") {
        originalSupply = 210e6 * 10**decimals(); // Initial supply of 210 million $C21
        _mint(msg.sender, originalSupply);
    }

    function burn(uint256 amount) public virtual override {
        super.burn(amount);
        emit Burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override {
        super.burnFrom(account, amount);
        emit Burn(account, amount);
    }
}