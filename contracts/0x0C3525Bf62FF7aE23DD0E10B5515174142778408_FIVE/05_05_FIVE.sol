/**
 * /** 
 *
 * $FIVE - Elon Musk's 5 Rules
 * https://www.youtube.com/watch?v=Qa_4c9zrxf0
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FIVE is ERC20 {
    string constant public boss = "Elon Musk";

    function owner() external pure virtual returns (address) {
        // owner renounced, no owner, for the stupid dextools
        return address(0);
    }

    constructor() ERC20("Elon Musk 5 Rules", "FIVE") {
        _mint(msg.sender, 555555555555 * 10 ** decimals());
    }
}