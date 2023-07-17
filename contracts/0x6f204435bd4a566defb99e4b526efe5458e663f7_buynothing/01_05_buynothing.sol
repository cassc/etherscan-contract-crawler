// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract buynothing is ERC20 {
    constructor() ERC20("buy nothing", "BNO") {
        _mint(msg.sender, 8000000000 * (10 ** 18));
    }
}