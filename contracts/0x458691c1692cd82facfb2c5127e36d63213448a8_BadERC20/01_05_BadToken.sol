// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title An ERC20 token that returns false on transfer, used only for tests.
contract BadERC20 is ERC20 {
    constructor() ERC20("MockToken", "MCKT") {
        _mint(msg.sender, 100 ether);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        super.transfer(to, amount);
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        super.transferFrom(from, to, amount);
        return false;
    }
}