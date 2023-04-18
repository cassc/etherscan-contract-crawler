// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Blo Funds Token
 * @author BLO-TEAM
 * @notice Contract to supply BND
 */
contract BND is ERC20 {
    constructor() ERC20("Blo Funds Token", "BND") {
        _mint(msg.sender, 21000000 * 1e18);
    }
}