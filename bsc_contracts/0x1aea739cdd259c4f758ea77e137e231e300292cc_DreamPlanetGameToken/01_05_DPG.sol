// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract DreamPlanetGameToken is ERC20 {

    constructor() ERC20("Dream Planet Gold", "DPG") {
        uint256 initialSupply = 1000000000 * 10 ** decimals();
        _mint(_msgSender(), initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}