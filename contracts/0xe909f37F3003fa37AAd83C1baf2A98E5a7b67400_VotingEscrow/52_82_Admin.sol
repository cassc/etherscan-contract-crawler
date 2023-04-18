// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "../interfaces/IHOPE.sol";

contract Admin {
    address hopeToken;

    constructor(address _hopeToken) {
        hopeToken = _hopeToken;
    }

    function mint(address to, uint256 amount) public {
        IHOPE(hopeToken).mint(to, amount);
    }

    function burn(uint256 amount) public {
        IHOPE(hopeToken).burn(amount);
    }
}