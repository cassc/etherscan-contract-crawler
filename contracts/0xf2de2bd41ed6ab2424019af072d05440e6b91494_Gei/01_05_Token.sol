//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Gei is ERC20 {
    uint constant _initial_supply = 1000000000 * (10**18);


    constructor() ERC20("kinda gei ngl", "GEI") {
        _mint(msg.sender, _initial_supply);

    }

}