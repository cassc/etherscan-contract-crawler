// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Twitter: https://twitter.com/pornhubfinance
// Telegram: https://t.me/pornhubfinance

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract PornHub is ERC20, Ownable {
    constructor() ERC20("PornHub Finance", "PORNHUB") {
        _mint(msg.sender, 1_000_000_000 * (10 ** 18));
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}