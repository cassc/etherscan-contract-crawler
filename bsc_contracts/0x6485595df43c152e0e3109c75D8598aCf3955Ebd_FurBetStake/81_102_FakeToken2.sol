// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeToken2 is ERC20
{
    constructor() ERC20("Fake Token 2", "FT2") {}

    function mint(address to_, uint256 amount_) external
    {
        super._mint(to_, amount_);
    }
}