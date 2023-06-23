// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @custom:security-contact [email protected]
contract FOREProtocol is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("FORE Protocol", "FORE") ERC20Permit("FORE Protocol") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}