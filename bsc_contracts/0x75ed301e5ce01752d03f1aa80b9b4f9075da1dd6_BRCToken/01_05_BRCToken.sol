// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BRCToken is ERC20 {

    uint256 public MAX_SUPPLY = 2 * 10 ** 28;

    constructor(address owner_) ERC20("Bridge Coin", "BRC") {
        _mint(owner_, MAX_SUPPLY);
    }

    function burn(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }
}