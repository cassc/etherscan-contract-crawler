// 😂 WHITEPAPER: https://lololololol.lol
// 😂 TELEGRAM: https://t.me/LOLVerification

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@boringcrypto/BoringSolidity/contracts/ERC20.sol";

contract LOL is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000000 * 1e18;
    mapping(address => bool) public blacklist;

    constructor() ERC20("LOL", "LOL") {
        _mint(msg.sender, _totalSupply);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!blacklist[to] && !blacklist[from]);
    }
}