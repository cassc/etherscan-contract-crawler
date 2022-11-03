// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./erc20/ERC20.sol";

contract CheckDot is ERC20 {
    // CheckDot token decimal
    uint8 public constant _decimals = 18;
    // Total supply for the CheckDot token = 10M
    uint256 private _totalSupply = 10000000 * (10 ** uint256(_decimals));
    // Token CheckDot deployer
    address private _checkDotDeployer;

    constructor(address _deployer) ERC20("CheckDot", "CDT") {
        require(_deployer != address(0), "CheckDot: deploy from the zero address");
        _checkDotDeployer = _deployer;
        _mint(_checkDotDeployer, _totalSupply);
    }

}