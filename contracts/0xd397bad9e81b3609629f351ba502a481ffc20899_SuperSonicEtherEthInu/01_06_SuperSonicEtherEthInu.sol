// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SuperSonicEtherEthInu is ERC20, Ownable {
    constructor() ERC20("SuperSonicEtherEthInu", "SHEI") {
        uint256 supply = (1000000000000) * 10**decimals();
        _mint(owner(), supply);
        renounceOwnership();
    }
}