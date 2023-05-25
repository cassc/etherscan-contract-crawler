// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RizzToken is Ownable, ERC20 {
    bool public limited;
    uint256 public maxWalletAmount;
    uint256 public minWalletAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor() ERC20("KISS", "RIZZ") {
        _mint(msg.sender, 555000000000000000000000000000000);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function flipLimited() external onlyOwner {
        limited = !limited;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setMaxWalletAmount(uint256 _maxWaletAmount) external onlyOwner {
        maxWalletAmount = _maxWaletAmount;
    }

    function setMinWaletAmount(uint256 _minWaletAmount) external onlyOwner {
        minWalletAmount = _minWaletAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
    require(!blacklists[to] && !blacklists[from], "Unallowed");

    if (uniswapV2Pair == address(0)) {
        require(from == owner() || to == owner(), "Unallowed");
        return;
    }

    if (limited && from == uniswapV2Pair) {
        require(super.balanceOf(to) + amount <= maxWalletAmount && super.balanceOf(to) + amount >= minWalletAmount, "Unallowed");
    }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
    
}