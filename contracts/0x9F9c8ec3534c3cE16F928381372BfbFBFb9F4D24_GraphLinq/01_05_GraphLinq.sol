// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./erc20/ERC20.sol";
import "./erc20/maths/SafeMath.sol";

contract GraphLinq is ERC20 {
    using SafeMath for uint256;
    // GraphLinq token decimal
    uint8 public constant _decimals = 18;
    // Total supply for the GraphLinq token = 500M
    uint256 private _totalSupply = 500000000 * (10 ** uint256(_decimals));
    // Token GraphLinq deployer
    address private _graphLinqDeployer;

    constructor(address _deployer) ERC20("GraphLinq", "GLQ", _decimals) {
        _graphLinqDeployer = _deployer;
        _mint(_graphLinqDeployer, _totalSupply);
    }

    // Allow to burn own wallet funds (which should be the amount from depositor contract)
    function burnFuel(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}