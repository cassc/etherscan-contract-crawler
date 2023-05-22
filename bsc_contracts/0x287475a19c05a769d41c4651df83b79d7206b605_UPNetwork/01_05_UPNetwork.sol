// SPDX-License-Identifier: MIT
// Telegram https://t.me/UpNetworkBSC
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract UPNetwork is ERC20 {

    constructor() ERC20("UP NETWORK", "UP") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}