// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name_, string memory symbol_)
        public
        // uint8 decimals_
        ERC20(name_, symbol_)
    {
        //  mint(10000000000 * (10**uint256(decimals_)));
    }

    function mint(uint256 amount) public returns (bool) {
        _mint(_msgSender(), amount);

        return true;
    }
}