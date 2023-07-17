/*

TELEGRAM: https://t.me/fumo2coin
TWITTER:  https://www.twitter.com/FUMO2coineth
WEBSITE:  https://www.fumo2coin.net

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FUMO2 is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint256 public mintAmount = 300 * 10 ** decimals();
    uint256 public maxHoldingAmount = mintAmount / 100;
    uint256 public swapTokensAtAmount = mintAmount / 1000;
    uint256 public fee = 2;

    bool public limitOn = true;
    bool public trading;
    bool public selling;
    bool public inSwapBack;
    bool public swapEnabled = true;

    mapping(address => bool) public blacklist;

    constructor() ERC20("Alien Milady Fumo 2.0", "FUMO2.0") {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
          .createPair(address(this), uniswapV2Router.WETH());
        // can only be called once
        _mint(msg.sender, mintAmount);
    }

    receive() external payable {}

    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function setRule(bool _trade, bool _sell, bool _limitOn, uint256 _maxHoldingAmount) external onlyOwner {
        trading = _trade;
        selling = _sell;
        limitOn = _limitOn;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklist[to] && !blacklist[from], "bl");
        if (!trading) {
            require(from == owner() || to == owner(), "no1");
        } else {
            require(selling || to != uniswapV2Pair, "no2");
            if (limitOn && from == uniswapV2Pair) {
                require(super.balanceOf(to) + amount <= maxHoldingAmount, "no3");
            }
        }

        uint256 contractTokenBalance = super.balanceOf(address(this));
        bool isBuy = (from == uniswapV2Pair);
        bool isSell = (to == uniswapV2Pair);
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (!inSwapBack && canSwap && swapEnabled && isSell) {
            inSwapBack = true;
            swapBack(contractTokenBalance / 2);
            inSwapBack = false;
        }

        // only take fees on buys/sells, do not take on wallet transfers or swapBack
        if (!inSwapBack) {
            if (isSell) {
                uint256 fees = amount * fee / 100;
                super._transfer(from, address(this), fees);
                amount -= fees;
            } else if (isBuy) {
          	    uint256 fees = amount * fee / 100;
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), 2**256-1);
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), 2**256-1);
        }

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack(uint256 amount) private {
        swapTokensForEth(amount);
        addLiquidity(balanceOf(address(this)), address(this).balance);
    }
}