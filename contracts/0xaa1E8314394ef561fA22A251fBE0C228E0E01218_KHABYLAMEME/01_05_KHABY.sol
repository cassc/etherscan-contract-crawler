// SPDX-License-Identifier: MIT

// TELEGRAM : https://t.me/KHABY_PORTAL

// TWITTER : https://twitter.com/khaby_lameme

// WEBSITE : https://www.khaby-lameme.com/

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract KHABYLAMEME is ERC20 {
    constructor() ERC20("KHABY LAMEME", "KHABY") {
        _mint(msg.sender, 100000000 * 10**decimals());
    }
}