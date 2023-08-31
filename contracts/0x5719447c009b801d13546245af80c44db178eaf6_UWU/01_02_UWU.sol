// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";

contract UWU is ERC20 {
    constructor() ERC20("Hentai Bot", "HENTAIBOT", 18) {
        _mint(msg.sender, 420_690_000 * 10**18);
    }
}