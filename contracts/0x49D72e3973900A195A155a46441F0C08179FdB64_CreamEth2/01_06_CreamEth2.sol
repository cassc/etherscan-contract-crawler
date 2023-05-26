// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CreamEth2 is ERC20Burnable {
    constructor() ERC20("Cream ETH Token", "CRETH2") {
        // total supply: 25166580578331153708082 (25166)
        _mint(msg.sender, 25166580578331153708082);
    }
}