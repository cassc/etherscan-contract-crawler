//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/IHoney.sol";
import "contracts/Validator.sol";

contract Honey is Validator, ERC20, IHoney {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        this;
    }

    function mint(address for_, uint256 amount) external override onlyValidator {
        _mint(for_, amount);
    }

    function burn(address for_, uint256 amount) external override onlyValidator {
        _burn(for_, amount);
    }
}