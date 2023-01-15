// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract CASTLE is ERC20, Ownable {
    bool public isTokenCreated;

    constructor(bool _isTokenCreated) ERC20("CASTLE", "$CASTLE") {
        isTokenCreated = _isTokenCreated;
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
    
}