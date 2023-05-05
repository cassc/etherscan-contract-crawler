/*

██████╗░░█████╗░███████╗██████╗░███████╗
██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝
██████╦╝███████║█████╗░░██████╔╝█████╗░░
██╔══██╗██╔══██║██╔══╝░░██╔═══╝░██╔══╝░░
██████╦╝██║░░██║███████╗██║░░░░░███████╗
╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚══════╝

The queen of crypto.

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BAEPE is ERC20 {

    constructor() ERC20("BAEPE", "BAEPE") {
        _mint(msg.sender, 69_420_000_000 * 10 ** decimals());
    }
}