// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Kayen is ERC20 {

    uint256 public constant TOTAL_SUPPLY = 10_000_000;

    constructor() ERC20("Kayen", "KAYEN") {
        _mint(msg.sender, TOTAL_SUPPLY * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

}