// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract KaleToken is ERC20 {
    constructor(address _distirbutor1) ERC20("Kale Currency","KALE") {
        _mint(_distirbutor1, 10_000_000_000 *1 ether);
    }
}