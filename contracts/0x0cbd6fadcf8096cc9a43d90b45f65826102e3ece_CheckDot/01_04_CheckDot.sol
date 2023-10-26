// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CheckDot is ERC20 {
    // CheckDot token decimal
    uint8 public constant _decimals = 18;
    // Total supply for the CheckDot token = 10M
    uint256 private _totalSupply = 10000000 * (10 ** uint256(_decimals));
    // Token CheckDot deployer
    address private _checkDotDeployer;

    constructor(address _deployer) ERC20("CheckDot", "CDT") {
        _checkDotDeployer = _deployer;
        _mint(_checkDotDeployer, _totalSupply);
    }

    // Allow to burn own wallet funds (which should be the amount from depositor contract)
    function burnFuel(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}