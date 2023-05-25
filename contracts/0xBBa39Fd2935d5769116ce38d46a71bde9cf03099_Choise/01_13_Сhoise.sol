// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Choise is Context, ERC20Votes {

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) ERC20Permit(_name) ERC20(_name, _symbol) {
        _mint(0x01399359d6307a7aCfa8EBf341FEa8B3D8b25C36, _initialSupply);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        require(_to != address(this), "Transfer to self not allowed");
        super._transfer(_from, _to, _amount);
    }
}