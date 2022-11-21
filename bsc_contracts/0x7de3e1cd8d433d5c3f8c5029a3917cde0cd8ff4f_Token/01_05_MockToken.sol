// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Token is ERC20 {
    uint256 private constant _INITIAL_SUPPLY = 1000000000 * (10**18);
    uint8 private decimals_;

    constructor(
        string memory _name,
        string memory _sybmol,
        uint8 _decimals,
        uint256 _mintAmount
    ) ERC20(_name, _sybmol) {
        _setupDecimals(_decimals);
        _mint(msg.sender, _mintAmount);
    }

    function _setupDecimals(uint8 _decimals) internal {
        decimals_ =_decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }
}