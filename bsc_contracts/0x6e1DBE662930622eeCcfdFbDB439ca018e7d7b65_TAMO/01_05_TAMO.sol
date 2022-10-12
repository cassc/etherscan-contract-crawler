// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TAMO is ERC20 {
    constructor(address addr_) ERC20("TAMO Token", "TAMO") {
        _mint(addr_, 100000000 ether);
    }
}