// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract MyToken is ERC20Upgradeable, Ownable2StepUpgradeable {
    uint8 private _myDecimals;

    function initialize(string memory _name, string memory _symbol, uint256 initialSupply, uint8 _decimals) external initializer {
        __Ownable2Step_init();
        __ERC20_init(_name, _symbol);
        _mint(_msgSender(), initialSupply);
        _myDecimals = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return _myDecimals;
    }
}