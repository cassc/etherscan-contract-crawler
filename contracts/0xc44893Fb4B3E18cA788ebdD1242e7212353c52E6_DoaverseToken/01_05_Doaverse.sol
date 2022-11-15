// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DoaverseToken is ERC20 {
    constructor(address addr) ERC20("Doaverse Token", "DO") {
        _mint(addr, 2 * 10**8 * 10**18);
    }
}