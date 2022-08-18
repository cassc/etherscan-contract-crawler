// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GemieToken is ERC20("GemieToken", "GEM") {
    uint256 private constant TOTAL_SUPPLY = 1000000000 ether;

    constructor(address genesisHolder) {
        require(genesisHolder != address(0), "GemieToken: zero address");
        _mint(genesisHolder, TOTAL_SUPPLY);
    }
}