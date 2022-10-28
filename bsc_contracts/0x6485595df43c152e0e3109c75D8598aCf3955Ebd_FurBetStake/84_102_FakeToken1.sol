// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeToken1 is ERC20
{
    constructor() ERC20("Fake Token 1", "FT1") {}

    function mint(address to_, uint256 amount_) external
    {
        super._mint(to_, amount_);
    }
}