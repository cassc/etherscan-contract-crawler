// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VB is ERC20 {

    constructor() ERC20("VB", "VB") {

        uint256 initialSupply = 1000_0000 * 10 ** 18;
        _mint(msg.sender, initialSupply);
    }


    function burn(uint256 amount) public {

        _burn(msg.sender, amount);
    }
}