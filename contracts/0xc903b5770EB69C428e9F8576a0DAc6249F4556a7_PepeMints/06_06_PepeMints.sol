pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// File contracts/PepeMints.sol


contract PepeMints is Ownable, ERC20 {

    constructor(uint256 _totalSupply) ERC20("PepeMints", "PepeMints") {
        _mint(msg.sender, _totalSupply);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}