// SPDX-License-Identifier: none
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Woof is ERC20 {
    constructor(uint256 initialSupply, address a) ERC20("WoofWork.co", "WOOF") {
        _mint(a, initialSupply); // To initialize pool
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}