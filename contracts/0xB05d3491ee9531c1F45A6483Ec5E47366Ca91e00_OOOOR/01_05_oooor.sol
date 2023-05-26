// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OOOOR is ERC20 {
    string private constant _name = "oooor";
    string private constant _symbol = "OOOOR";
    uint256 private constant _totalSupply = 1e9 * 10**18;
    uint8 private _decimals = 18;

    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}