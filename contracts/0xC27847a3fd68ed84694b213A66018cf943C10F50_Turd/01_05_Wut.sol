// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Turd is ERC20 {
    uint256 private constant _tTotal = 42000000000 * 10**18;
    constructor() ERC20("Turd", "TURD") {
        
        _mint(msg.sender, _tTotal);
    }
}