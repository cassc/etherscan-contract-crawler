// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ponzi is ERC20 {

    uint256 constant initialSupply = 100000000000 * (10**18);

    constructor() ERC20("PONZI", "PZI") {
        _mint(msg.sender, initialSupply);
    }
}