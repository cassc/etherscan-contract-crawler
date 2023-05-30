// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0<0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Love is ERC20 {
    constructor() ERC20("LOVE", "LV") {
        _mint(msg.sender, 3800000000 * 10 ** decimals());
    }
}