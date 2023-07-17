// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Miracle is Ownable, ERC20, ERC20Burnable {
    string public tokenName;
    string public tokenSymbol;
    address public pairAddress;
    uint256 public maxTokenHoldings;
    mapping(address => bool) public blacklist;
    constructor(string memory _tokenName, string memory _tokenSymbol, address[] memory recipients, uint256[] memory amounts) ERC20(_tokenName, _tokenSymbol) {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        maxTokenHoldings = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        for (uint i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
        }
    }
    function setBlacklisted(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }
    function setPair(address _pair) external onlyOwner {
        pairAddress = _pair;
    }
    function setMaxHoldings(uint256 _maxTokenHoldings) external onlyOwner {
        maxTokenHoldings = _maxTokenHoldings;
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklist[to] && !blacklist[from], "Blacklisted, sorry");
        if (from == pairAddress) {
            require(super.balanceOf(to) + amount <= maxTokenHoldings, "Bag too large, sorry");
        }
    }
}