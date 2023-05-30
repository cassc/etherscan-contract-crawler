// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract PARTYToken is ERC20 {
    constructor(uint256 initialSupply, address _initialWallet) public ERC20("MONEY PARTY", "PARTY") {
        _setupDecimals(6);
        _mint(_initialWallet, initialSupply * (10 ** uint256(decimals())));
    }
}

