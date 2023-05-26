//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TEAMERC20 is ERC20 {
    constructor() ERC20("TEAM token", "TEAM"){
        _mint(msg.sender, 88888888 * (10 ** uint256(decimals())));
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}