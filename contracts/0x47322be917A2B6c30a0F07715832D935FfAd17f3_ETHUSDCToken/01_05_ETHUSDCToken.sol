// contracts/ETHUSDC.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ETHUSDCToken is ERC20 {
    constructor() ERC20("EthUsdc.org", "EthUsdc.org") {
        _mint(msg.sender,1000000000 * 10**18);
    }
}