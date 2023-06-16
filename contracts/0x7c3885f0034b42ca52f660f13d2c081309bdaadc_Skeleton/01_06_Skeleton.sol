/**

TG: https://t.me/+rUA8mi4uIUVhY2Fh
TWITTER: https://twitter.com/thisisskeleton
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Skeleton is ERC20, Ownable {
    constructor() ERC20("SKELETON", "SKELE") {
        _mint(msg.sender, 187000000000 * 10 ** decimals());
    }
}