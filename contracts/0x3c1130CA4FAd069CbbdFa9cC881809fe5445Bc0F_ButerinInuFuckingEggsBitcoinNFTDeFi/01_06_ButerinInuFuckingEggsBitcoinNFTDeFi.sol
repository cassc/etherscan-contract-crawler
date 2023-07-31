// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ButerinInuFuckingEggsBitcoinNFTDeFi is ERC20, Ownable {
    constructor() ERC20("ButerinInuFuckingEggsBitcoinNFTDeFi", "BALLS") {
        _mint(msg.sender, 69_000_000 * 1e18);
    }
}