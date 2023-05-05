/*
    Website: https://ethforce.xyz
    Twitter: https://twitter.com/ethereumforce
    Telegram: https://t.me/forceeth
    
    Welcome to the good side fellow Jedi's! 
    After the presale airdrop completed, contract ownership will be renounced and liquidity will be locked. 
    May the force be with degeneracy.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

// Safe as force contract, full vanilla
contract Force is ERC20, Ownable {
    constructor() ERC20("May the 4th Be With You!", "FORCE") {
        _mint(msg.sender, 4_000_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function mayTheForce() public pure returns (string memory) {
        return "be with you";
    }
}