// SPDX-License-Identifier: Unlicense
/* 
$BITCH TOKEN UP ON MY SHIT $BITCH WE FINNA GET RICH

Twitter: https://twitter.com/bitchcoineth_
Telegram: https://t.me/BitchCoinentry
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BitchCoin is Ownable, ERC20 {
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor() ERC20("BitchCoin", "BITCH") {
        _mint(msg.sender, 420696969696000000000000000000);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setUniswapPair(
        address _uniswapV2Pair
    ) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}