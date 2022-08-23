// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockToken is ERC20 {

    uint8 tokenDecimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol) {
        tokenDecimals = _decimals;
    }

    function mint(address _to, uint _amount) external returns (uint) {
        _mint(_to, _amount);
        return _amount;
    }

    function burn(address _to, uint _amount) external {
        _burn(_to, _amount);
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return tokenDecimals;
    }
}