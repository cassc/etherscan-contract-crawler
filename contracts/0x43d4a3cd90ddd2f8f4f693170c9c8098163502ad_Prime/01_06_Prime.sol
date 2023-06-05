/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/
// SPDX-License-Identifier: GPL-3.0-or-later
// solium-disable linebreak-style

pragma solidity 0.8.6;

import "openzeppelin-contracts-sol8/token/ERC20/extensions/ERC20Capped.sol";

/**
 * @title Prime token contract
 * @dev   PrimeDAO v2 native contract.
 */
contract Prime is ERC20Capped {
    uint256 supply = 100000000000000000000000000;

    constructor() public ERC20("Prime", "D2D") ERC20Capped(supply) {
        ERC20._mint(msg.sender, supply);
    }
}