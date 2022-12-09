// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GalactixZoneToken is ERC20 {
    constructor(address _admin, uint256 _totalGXZSupply) ERC20("Galactix Zone", "GXZ") {
        require(_admin != address(0), "GXZ-TOKEN: ZERO ADDRESS");
        _mint(_admin, _totalGXZSupply);
    }
}