// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YIQITOKEN is ERC20 {
    constructor() ERC20("YIQI TOKEN", "YIQ") {
        _mint(msg.sender, 666 * (10 ** 18));
    }
}