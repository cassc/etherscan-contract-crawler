// SPDX-License-Identifier: MIT

/**
Explore the new LimeWire: https://limewire.com
LimeWire (LMWR) Token: https://lmwr.com
Community: https://limewire.com/bio
WhitePaper: https://lmwr.com/downloads/LimeWire Whitepaper 1.0.pdf
Twitter: https://twitter.com/limewire
Discord: https://discord.gg/limewire
Instagram: https://instagram.com/limewire

 /$$       /$$                         /$$      /$$ /$$                           /$$$$$$$$        /$$
| $$      |__/                        | $$  /$ | $$|__/                          |__  $$__/       | $$
| $$       /$$ /$$$$$$/$$$$   /$$$$$$ | $$ /$$$| $$ /$$  /$$$$$$   /$$$$$$          | $$  /$$$$$$ | $$   /$$  /$$$$$$  /$$$$$$$
| $$      | $$| $$_  $$_  $$ /$$__  $$| $$/$$ $$ $$| $$ /$$__  $$ /$$__  $$         | $$ /$$__  $$| $$  /$$/ /$$__  $$| $$__  $$
| $$      | $$| $$ \ $$ \ $$| $$$$$$$$| $$$$_  $$$$| $$| $$  \__/| $$$$$$$$         | $$| $$  \ $$| $$$$$$/ | $$$$$$$$| $$  \ $$
| $$      | $$| $$ | $$ | $$| $$_____/| $$$/ \  $$$| $$| $$      | $$_____/         | $$| $$  | $$| $$_  $$ | $$_____/| $$  | $$
| $$$$$$$$| $$| $$ | $$ | $$|  $$$$$$$| $$/   \  $$| $$| $$      |  $$$$$$$         | $$|  $$$$$$/| $$ \  $$|  $$$$$$$| $$  | $$
|________/|__/|__/ |__/ |__/ \_______/|__/     \__/|__/|__/       \_______/         |__/ \______/ |__/  \__/ \_______/|__/  |__/

**/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lmwr is ERC20 {

    constructor() ERC20("LimeWire Token", "LMWR") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}