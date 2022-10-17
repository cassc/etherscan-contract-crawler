// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract DreamPlanetToken is ERC20 {

    constructor() ERC20("Dream Planet Coin", "DPC") {
        uint256 initialSupply = 100000000 * 10 ** decimals();
        _mint(_msgSender(), initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}