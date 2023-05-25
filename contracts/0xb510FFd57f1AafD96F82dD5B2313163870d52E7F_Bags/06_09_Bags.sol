// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract Bags is ERC20, Ownable {
    uint256 public maxWalletHolding;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply, uint256 _maxWalletHolding) ERC20("Bags", "BAGS") {
        maxWalletHolding = _maxWalletHolding;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        _mint(msg.sender, _totalSupply);
    }

    function setMaxWalletHolding(uint256 maxHolding) external onlyOwner {
        maxWalletHolding = maxHolding;
    }

    function blacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklists[_address] = _isBlacklisted;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!blacklists[to] && !blacklists[from] && !blacklists[tx.origin], "Blacklisted");

        if (from != owner() && to != owner() && to != uniswapV2Pair && to != address(0xdead)) {
            require(super.balanceOf(to) + amount <= maxWalletHolding, "Recipient exceeds max wallet size.");
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}