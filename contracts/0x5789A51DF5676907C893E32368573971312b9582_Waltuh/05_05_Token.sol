//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Waltuh is ERC20 {
    uint constant _initial_supply = 420690000000000 * (10**18);
    constructor() ERC20("open na noor", "WALTUH") {
        _mint(msg.sender, _initial_supply);
    }
}