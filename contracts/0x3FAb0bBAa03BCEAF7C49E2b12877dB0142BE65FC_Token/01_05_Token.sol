// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        _mint(_msgSender(), _initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}