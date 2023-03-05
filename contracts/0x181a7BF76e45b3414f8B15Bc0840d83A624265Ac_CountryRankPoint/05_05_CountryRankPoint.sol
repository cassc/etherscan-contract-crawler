// SPDX-License-Identifier: none
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract CountryRankPoint is ERC20 {
    constructor(uint256 initialSupply, address a) ERC20("Country Rank Point", "CRNK") {
        _mint(a, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}