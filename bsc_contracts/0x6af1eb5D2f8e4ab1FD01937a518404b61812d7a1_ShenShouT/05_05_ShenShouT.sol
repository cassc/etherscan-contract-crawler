// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShenShouT is ERC20 {

    uint256 public _cap = 1000000000 * 10 ** 18;

    constructor() ERC20("ShenShouT", "ShenShouT") {
        _mint(msg.sender, _cap);
    }
}