// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrawMushroom is Ownable, ERC20 {
    mapping(address => bool) public blacklists;
    constructor(uint256 _totalSupply) ERC20("StrawMushroom", "STROOM") {
        _mint(msg.sender, _totalSupply * 10 ** decimals());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }

    function blacklist(address _address, bool _blacklisted) external onlyOwner {
        blacklists[_address] = _blacklisted;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}