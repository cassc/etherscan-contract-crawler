// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @custom:security-contact [email protected]
contract ConeToken is ERC20 {
    constructor() ERC20("CRYPTO ONE", "CONE") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}