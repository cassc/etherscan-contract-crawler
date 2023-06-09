// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DREAMO is Ownable, ERC20 {
    uint256 public constant TOTAL_SUPPLY = 711_711_711_711_711 * 1 ether;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor() ERC20("DREAMO", "DREAMO") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

  function blacklist(address _address, bool _isBlacklist) external onlyOwner {
        blacklists[_address] = _isBlacklist;
    }

    function setRule(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(
    address from,
    address to,
    uint256 
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading has not started");
            return;
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}