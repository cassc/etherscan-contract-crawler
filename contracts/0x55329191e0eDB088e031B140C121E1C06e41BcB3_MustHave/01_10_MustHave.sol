//SPDX-License-Identifier: MIT
/*
…………______
…………/……..\
………../……….\
………..|………..|
………..|………..|
………..|………..|._____.._____.
………..|………..||…….|.|…….|.._____.
………..|………..||…….|.|…….|.|…….|
………..|…………|..___|_|_____|.|……..|
………..|…………/…………….___.\..__..|
………..|………./………………|__|.|.|_|..|
………..|……./…………_________/.\.__./
………..|…./……………/……………….|
………..|../……………/…………………|
………..|/………………)………………./
………..|………………..)……………./
………..\…………………)…………../
…………\……………………………./
………….\…………………………./
……………\………………………/
……………|……………………..|

█▀▄▀█ █░█ █▀ ▀█▀   █░█ ▄▀█ █░█ █▀▀
█░▀░█ █▄█ ▄█ ░█░   █▀█ █▀█ ▀▄▀ ██▄
*/
pragma solidity ^0.8.5;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MustHave is ERC20, Ownable {
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public rt;
    address public pair;
    uint256 fee = 3;
    bool private openTr;

    constructor() ERC20("Must Have", "MUSTH") {
        rt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(rt.factory()).createPair(
            rt.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(0xdead)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(0xdead)] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    uint256 _totalSupply = 100000000 * (10**decimals());
    uint256 public _maxW = (_totalSupply * 4) / 100;
    mapping(address => bool) isFeeExempt;

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!openTr) {
            require(
                isFeeExempt[sender] || isFeeExempt[recipient],
                "Trading is not active."
            );
        }
        if (recipient != pair && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxW,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 taxed = shouldTakeFee(sender) ? getFee(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    receive() external payable {}

    function openTrading() external onlyOwner {
        openTr = true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getFee(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fee) / 100;
        return feeAmount;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function setLimit(uint256 amount) external onlyOwner {
        _maxW = (_totalSupply * amount) / 100;
    }
}