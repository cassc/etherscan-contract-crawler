// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact [email protected]
contract OracleBinance is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Oracle Bianace", "ORB") {
        _mint(msg.sender, 7968464716 * 10 ** decimals());
    }
}
