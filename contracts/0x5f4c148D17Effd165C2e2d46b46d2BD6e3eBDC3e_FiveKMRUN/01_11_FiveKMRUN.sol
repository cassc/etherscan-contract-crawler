// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract FiveKMRUN is ERC20, ERC20Permit {
    constructor() ERC20("FiveKM RUN", "RUN") ERC20Permit("FiveKM RUN") {
        _mint(msg.sender, 7000000000 * 10 ** decimals());
    }
}