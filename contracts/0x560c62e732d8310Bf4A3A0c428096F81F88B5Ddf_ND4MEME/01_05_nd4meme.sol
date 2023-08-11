// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ND4MEME is ERC20 {
    constructor() ERC20("nd4 meme", "ND4MEME") {
        uint256 initialSupply = 10000000000;
        _mint(msg.sender, initialSupply * (10**decimals()));
    }
}