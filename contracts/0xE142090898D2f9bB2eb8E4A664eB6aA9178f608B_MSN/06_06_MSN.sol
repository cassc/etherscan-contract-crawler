// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

contract MSN is ERC20, Ownable {
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply) ERC20("MSN", "MSN") {
        _mint(msg.sender, _totalSupply);
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function airdropTokens(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Mismatched input arrays");

        for (uint256 i; i < _recipients.length;) {
            _transfer(owner(), _recipients[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0) && from != address(0)) {
            require(from == owner(), "trading is not started");
            return;
        }
    }
}