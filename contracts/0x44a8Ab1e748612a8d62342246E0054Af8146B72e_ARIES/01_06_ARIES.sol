// ♈️ TELEGRAM: https://t.me/AriesPortal

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin/openzeppelin-contracts/token/ERC20/ERC20.sol";

contract ARIES is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000000 * (10**18);
    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist;

    constructor() ERC20("Aries", "ARIES") {
        _mint(msg.sender, _totalSupply);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!blacklist[to] && !blacklist[from]);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function toggleBlacklist(address _address, bool _blacklist) external onlyOwner {
        blacklist[_address] = _blacklist;
    }
}