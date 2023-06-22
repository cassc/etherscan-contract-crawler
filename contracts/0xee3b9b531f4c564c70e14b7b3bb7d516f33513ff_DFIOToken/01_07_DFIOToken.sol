// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract DFIOToken is ERC20Burnable {
    constructor(uint256 initialSupply) public ERC20("DeFi Omega", "DFIO") {
        _mint(msg.sender, initialSupply);
    }
}