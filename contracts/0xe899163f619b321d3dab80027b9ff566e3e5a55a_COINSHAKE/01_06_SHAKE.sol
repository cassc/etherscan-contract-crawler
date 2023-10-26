// WEB: https://coinshake.co/
// X: https://twitter.com/COIN_SHAKE
// TG: https://t.me/COINSHAKEPortal

/*

Stirring Up Blockchain Transactions for Ultimate Anonymity
In the evolving landscape of transparent digital transactions, 
COIN SHAKE stands as a fortress of privacy, 
bringing a fresh perspective to ensuring transactional anonymity in the blockchain space.

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract COINSHAKE is ERC20 { 
    constructor() ERC20("COIN SHAKE", "SHAKE") { 
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}