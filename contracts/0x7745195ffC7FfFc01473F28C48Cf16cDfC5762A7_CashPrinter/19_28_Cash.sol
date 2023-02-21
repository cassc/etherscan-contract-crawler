// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cash is ERC20 {
    address private _minter;

    modifier onlyMinter() {
        require(
            msg.sender == _minter,
            "Caller is not the minter"
        );
        _;
    }

    function mint(address to, uint amount) external onlyMinter {
        _mint(to, amount);
    }

    constructor(address minter_) ERC20("Cash", "CASH") {
        _minter = minter_;
    }
}