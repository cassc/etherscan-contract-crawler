// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Base.sol";

contract BaseTemplate is ERC20Base {
    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        uint256 amount_
    ) external virtual initializer {
        __ERC20Base_init(name_, symbol_, decimals_, amount_);
    }
}