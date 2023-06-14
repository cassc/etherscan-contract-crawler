/*
    ____  ___   ____  __    ___    ______  __
   / __ \/   | / __ \/ /   /   |  / __ \ \/ /
  / / / / /| |/ / / / /   / /| | / / / /\  /
 / /_/ / ___ / /_/ / /___/ ___ |/ /_/ / / /
/_____/_/  |_\____/_____/_/  |_/_____/ /_/

    https://opensea.io/collection/milady
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAOLADY is Ownable, ERC20 {
    uint256 private _totalSupply = 25000000 * (10 ** 18);

    constructor() ERC20("Milady Maker DAO", "DAOLADY", 18) {
        _mint(msg.sender, _totalSupply);
    }
}