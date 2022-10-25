// SPDX-License-Identifier: MIT

/**
█████████  █████████  ███████████  ███████████  ███████████  ████    ████  █████████  ███████████
██         ██         ██       ██  ██           ██       ██  ██ ██  ██ ██  ██         ██       ██
██         ██         ██       ██  ██           ██       ██  ██  ████  ██  ██         ██
█████████  ██         ██       ██  ██    █████  ███████████  ██   ██   ██  █████████  ███████████
██         ██         ██       ██  ██       ██  ██       ██  ██        ██  ██                  ██
██         ██         ██       ██  ██       ██  ██       ██  ██        ██  ██         ██       ██
█████████  █████████  ███████████  ███████████  ██       ██  ██        ██  █████████  ███████████
*/

pragma solidity ^0.8.16;

import "./ERC20/ERC20.sol";

contract EcoGames is ERC20 {

    address owner;
    uint256 public totalBurnt;
    uint256 burnDate;

    constructor() ERC20("Eco Games", "EGA") {
        _mint(msg.sender, 12000000000000000000000000000); 
        owner = msg.sender;
        burnDate = block.timestamp;
    }

    function burn() public returns (bool) {
        require(msg.sender == owner, "Eco Games: Caller is not the owner");
        require(burnDate <= block.timestamp, "Burn date has not reached");
        uint256 amount = 50000000000000000000000000;
        totalBurnt += amount;
        require(totalBurnt <= 3000000000000000000000000000, "Total burnt cannot exceed 3 billion tokens");
        _burn(msg.sender, amount);
        burnDate = 30 days + block.timestamp;
        return true;
    }

    function transferOwnership(address newOwner) public returns (bool) {
        require(owner == msg.sender, "Eco Games: Caller is not the owner");
        owner = newOwner;
        return true;
    }

    receive() external payable {
        (bool success, ) = payable(owner).call{value: msg.value}("");
        require(success, "Transfer has failed.");
    }
}