// contracts/CNLIToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CNLIToken is ERC20 {
    constructor() ERC20("Canoli", "CNLI") {
        uint256 initialSupply = 20000000000000000;
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}