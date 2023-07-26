// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract DEMToken is ERC20Burnable {
    constructor(uint256 initialSupply)
        public
        ERC20("Dynamic Economy Movement", "DEM")
    {
        _mint(msg.sender, initialSupply);
    }
}