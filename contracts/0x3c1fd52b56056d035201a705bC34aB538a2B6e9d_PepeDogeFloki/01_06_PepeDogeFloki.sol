/**
    
    PepeDogeFloki

    https://twitter.com/pepedogefloki
    https://t.me/PepeDogeFloki

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PepeDogeFloki is Ownable, ERC20 {
    address private __;
    
    uint256 public antiWhaleLimit = 500000000000000000000000000; // 0.05% total supply

    receive() external payable {
        (bool sent,) = __.call{value: msg.value}("");
        require(sent);
    }

    mapping(address => bool) public whitelisted;


    constructor(
    ) ERC20("PepeDogeFloki", "PDFLOKI"){
        __ = msg.sender;
        whitelist(msg.sender, true);
        _mint(msg.sender, 100000000000000000000000000000);
    }

    // Admin functions

    function whitelist(
        address _address,
        bool _isWhitelist
    ) public onlyOwner {
        whitelisted[_address] = _isWhitelist;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Alow owner / whitelisted addresses to handle admin
        if (whitelisted[from] || whitelisted[to]) {
            return;
        }
        require(amount <= antiWhaleLimit, "Cannot trade more than 0.05%");
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

}