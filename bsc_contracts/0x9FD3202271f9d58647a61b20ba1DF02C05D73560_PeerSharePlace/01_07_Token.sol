// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PeerSharePlace is ERC20, Ownable {

    uint256 constant private _initial_supply = 1_000_000_000 * (10**18);

    constructor() ERC20("PeerSharePlace", "BLOCK") {
        
        _mint(msg.sender,_initial_supply);
        
    }

}