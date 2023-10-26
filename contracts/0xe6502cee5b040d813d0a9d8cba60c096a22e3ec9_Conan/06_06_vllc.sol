// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";
import "ReentrancyGuard.sol";

/// @custom:security-contact [email protected]
contract Conan is ERC20 {
    constructor() ERC20("Conan", "vllc") {
        _mint(msg.sender, 22101970000 * 10 ** decimals());
    }
}
