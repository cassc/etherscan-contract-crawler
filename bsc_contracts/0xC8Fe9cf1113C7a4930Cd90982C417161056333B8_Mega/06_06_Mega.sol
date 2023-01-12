// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mega is ERC20, Ownable {

    constructor(address creator) ERC20("MEGA COIN", "MEGA") {
        _mint(creator, 7777777777 * 10 ** decimals());
    }
}