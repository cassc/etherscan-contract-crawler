// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DonPepe is ERC20, ERC20Burnable, Ownable {

    using SafeMath for uint256;
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    address private _devWallet;
    uint256 private constant _maxSupply = 21000000000 * 10**18; //21 billion

    uint256 private constant _feeRate = 3; // 0.3% fee
    uint256 private constant _feeDivider = 1000;

    constructor(address devWallet) ERC20("DonPepe", "DONPEPE") {
        require(devWallet != address(0), "Cannot be zero");
        _devWallet = devWallet;
        _mint(msg.sender, _maxSupply);
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 feeAmount = amount.mul(_feeRate).div(_feeDivider);
        uint256 transferAmount = amount.sub(feeAmount);

        super._transfer(sender, recipient, transferAmount);
        if (feeAmount > 0) {
            super._transfer(sender, _devWallet, feeAmount);
        }
    }

    function maxSupply() public pure returns (uint256) {
        return _maxSupply;
    }

    function burn(uint256 amount) override public {
        _burn(msg.sender, amount);
    }

}