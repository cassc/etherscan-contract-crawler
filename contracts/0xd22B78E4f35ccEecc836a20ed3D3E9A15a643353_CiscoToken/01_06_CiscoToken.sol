// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "ERC20.sol";
import "Ownable.sol";


contract CiscoToken is ERC20, Ownable {
    uint256 public supply;

    constructor() ERC20("Cisco", "CSC") {
        uint256 totalSupply = 3.000_000_000e9 * 1e18;
        supply = totalSupply;
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        super._transfer(from, to, amount);
    }
}