// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Rainmaker is ERC20 {
    constructor() ERC20("Rainmaker Games", "RAIN") {
        _mint(0xFE5Fc6a94989DC212bc0e8EEc21EeaD8999C8333, 1e27);
    }
}