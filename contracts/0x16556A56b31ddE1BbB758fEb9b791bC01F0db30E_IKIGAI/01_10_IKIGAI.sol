//SPDX-License-Identifier: MIT
/*

                 .--.   ( ZZZZZZZZZZZZZZZZZZZZ! )
    ----------__/  u\u  /'-------------------------------------------
      `-'`-'  \ |(   C|
               \ \_  -'--.       `-'`-'`-'
                \|   . "-.\                      `-'`-'`-'
     `-'`-'`-'   \\ \______\\___
    --------------\\_____\)'--.-)----------------------------------
                /  \ / (  |    \ \
     VK        /    \__.`-|--\  \ \
              /__.--'     |   `. \__--.
             '            |     )___\--`
  
        Meaning in Life
       “What you love” 
     “ What you are good at”
    “What the world needs” and 
   “What you can be paid for”. 
*/

pragma solidity ^0.8.5;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IKIGAI is ERC20, Ownable {
    string constant _name = "IKIGAI";
    string constant _symbol = "IKIGAI";

    uint256 fee = 2;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public rt;
    address public pair;

    uint256 _totalSupply = 9000000000 * (10**decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 4) / 100;
    mapping(address => bool) isFeeExempt;

    bool private tradingActive;

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!tradingActive) {
            require(
                isFeeExempt[sender] || isFeeExempt[recipient],
                "Trading is not active."
            );
        }
        if (recipient != pair && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 taxed = shouldTakeFee(sender) ? getFee(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    receive() external payable {}

    function setLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    function openTrading() external onlyOwner {
        tradingActive = true;
    }

    constructor() ERC20(_name, _symbol) {
        rt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(rt.factory()).createPair(
            rt.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(0xdead)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function getFee(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fee) / 100;
        return feeAmount;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
}