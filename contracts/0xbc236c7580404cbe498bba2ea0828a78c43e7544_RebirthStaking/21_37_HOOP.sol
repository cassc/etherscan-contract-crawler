// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrimalHoop is ERC20, Ownable {

    uint256 public immutable _maxSupply;

    constructor() ERC20("Primal Hoop", "HOOP") {
        _maxSupply = 350000000000000000000000000;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        require(totalSupply() <= _maxSupply, "Total supply higher than max supply.");
    }
}