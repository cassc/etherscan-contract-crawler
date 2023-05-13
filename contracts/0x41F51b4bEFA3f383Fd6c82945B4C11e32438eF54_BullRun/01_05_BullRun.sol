// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract BullRun is ERC20 {
    using SafeMath for uint256;
    // BullRun token decimal
    uint8 public constant _decimals = 18;
    // Total supply for the BullRun token = 5000M
    uint256 private _totalSupply = 5000000000 * (10 ** uint256(_decimals));
    // Token BullRun deployer
    address private _BullRunDeployer;

    constructor(address _deployer) ERC20("BullRun", "BULLRUN", _decimals) {
        _BullRunDeployer = _deployer;
        _mint(_BullRunDeployer, _totalSupply);
    }

    // Allow to burn own wallet funds (which should be the amount from depositor contract)
    function burnFuel(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}