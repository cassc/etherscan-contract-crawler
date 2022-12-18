// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/BEP20.sol";
import "../libraries/CopyrightToken.sol";

/**
 * @dev FreeToken: Demo BEP20 implementation
 */
contract FreeToken is BEP20, CopyrightToken {
    constructor(string memory name_, string memory symbol_) BEP20(name_, symbol_) CopyrightToken("2.0") {
        // mint 10,000 tokens to the contract deployer
        _mint(_msgSender(), 10000 * 10 ** 18);
    }
}