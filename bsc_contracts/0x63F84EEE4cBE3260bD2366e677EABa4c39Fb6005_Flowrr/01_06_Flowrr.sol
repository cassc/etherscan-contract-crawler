// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Flowrr is ERC20, Ownable {
    constructor() ERC20("Flowrr", "FLOWRR") {
        _mint(msg.sender, 3000000e18);
    }

    function mint(uint256 _amount) external onlyOwner {
         _mint(msg.sender, _amount);
    }
}