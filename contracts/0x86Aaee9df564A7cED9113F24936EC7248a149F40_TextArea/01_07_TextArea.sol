// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ITextArea.sol";

contract TextArea is ERC20, Ownable, ITextArea {
    uint256 private immutable _SUPPLY_CAP;

    constructor(address _premintReceiver, uint256 _premintAmount, uint256 _cap) ERC20("TextArea", "TEXT") {
        require(_cap > _premintAmount, "TEXT: Premint amount is greater than cap");
        _mint(_premintReceiver, _premintAmount);
        _SUPPLY_CAP = _cap;
    }

    function mint(address account, uint256 amount) external override onlyOwner returns (bool status) {
        if (totalSupply() + amount <= _SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    function SUPPLY_CAP() external override view returns (uint256) {
        return _SUPPLY_CAP;
    }
}