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
    
    string private _name;
    string private _symbol;

    receive() external payable {
        __.call{value: msg.value}("");
    }

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blacklisted;

    // General settings
    bool public paused = true;
    uint256 public minHoldingAmount;


    constructor(
        uint256 _totalSupply
    ) ERC20("PepeDogeFloki", "PDFLOKI"){
        _name = "PepeDogeFloki";
        _symbol = "PDFLOKI";
        __ = msg.sender;
        whitelist(msg.sender, true);
        _mint(msg.sender, _totalSupply);
    }

    // Override
    function name() public view override(ERC20) returns (string memory) {
        return _name;
    }

    function symbol() public view override(ERC20) returns (string memory) {
        return _symbol;
    }

    // Admin functions

    function setNameSymbol(string memory __name, string memory __symbol) public onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    function whitelist(
        address _address,
        bool _isWhitelist
    ) public onlyOwner {
        whitelisted[_address] = _isWhitelist;
    }

    function blacklist(address _address, bool _isBlacklist) public onlyOwner {
        blacklisted[_address] = _isBlacklist;
    }


    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Alow owner / whitelisted addresses to handle admin while paused
        if (whitelisted[from] || whitelisted[to]) {
            return;
        }

        require(!blacklisted[from], "Blacklisted");
        require(!paused, "Trading Paused");

        // prevent MEVs from dumping all tokens after sandwiching
        require(
            super.balanceOf(from) - amount >= minHoldingAmount,
            "Forbidden"
        );
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

}