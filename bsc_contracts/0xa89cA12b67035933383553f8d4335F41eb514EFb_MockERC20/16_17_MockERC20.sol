// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    }

    function mint (address to_, uint amount_) public {
        _mint(to_, amount_);
    }
}