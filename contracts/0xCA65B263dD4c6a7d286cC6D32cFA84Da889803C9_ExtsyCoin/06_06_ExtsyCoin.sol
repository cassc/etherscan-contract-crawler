// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExtsyCoin is ERC20, Ownable {
    mapping(address => bool) public blacklists;

    constructor() ERC20("Extsy", "EXTSY") {
        uint256 totalSupply = 50_000_000 ether;
        _mint(msg.sender, totalSupply);
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
}