// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @custom:security-contact [email protected]
contract ZGT is ERC20 {
    constructor() ERC20("zkFinance Governance Token", "ZGT") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}