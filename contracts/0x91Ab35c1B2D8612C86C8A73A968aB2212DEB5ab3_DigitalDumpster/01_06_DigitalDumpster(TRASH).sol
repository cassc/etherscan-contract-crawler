pragma solidity ^0.8.20;
// SPDX-License-Identifier: UNLICENSED

// WEBSITE DIGITALDUMPSTER.XYZ 
// TWITTER @TRASHCOINETH

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DigitalDumpster is ERC20, Ownable {
    constructor() ERC20("DigitalDumpster", "TRASH") {
        _mint(msg.sender, 28000000 * 10 ** decimals());
    }

    function transferTokens(address to, uint256 amount) public onlyOwner {
        _transfer(owner(), to, amount);
    }
}