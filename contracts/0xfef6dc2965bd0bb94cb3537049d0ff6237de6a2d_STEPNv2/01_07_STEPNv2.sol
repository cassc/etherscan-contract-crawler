// SPDX-License-Identifier: GPL-3.0

/*
STEPN 2.0 - STEPNv2
tg: https://t.me/stepn20_erc
tw: https://twitter.com/stepnv2
web:
*/

pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract STEPNv2 is ERC20, Ownable {
    using SafeMath for uint256;

    IRouter public router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public pair;

    bool private inSwap = false;
    bool private swapEnabled = false;

    address payable private _taxWallet = payable(0x242851bd845b085763C9f2A133FF2A72c1D952b8);

    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _lastTransfer;
    bool public transferDelay = true;

    uint256 private _buyTax = 1;
    uint256 private _sellTax = 1;

    uint256 private _firstBuyTax = 20;
    uint256 private _firstSellTax = 25;

    uint256 private _firstBuyTaxAt = 20;
    uint256 private _firstSellTaxAt = 30;

    uint256 private _buyCount = 0;

    uint8 private constant _decimals = 18;
    uint256 private constant _supply = 1000000000 * 10**_decimals;

    uint256 private _swapAt = 25;
    uint256 private _swapThreshold = _supply * 15 / 1000;
    uint256 private _swapMax = _supply * 15 / 1000;

    uint256 public maxBuy = _supply * 2 / 100;
    uint256 public maxWallet = _supply * 2 / 100;
    uint256 private _maxAt = 2;

    bool public isLimited = true;
    uint256 private _openTrade;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20("STEPN 2.0", "STEPNv2") {
        _mint(owner(), _supply);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

    
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function buyTax() public view returns(uint256) {
        return _buyCount >= _firstBuyTaxAt ? _buyTax : _firstBuyTax;
    }

    function sellTax() public view returns(uint256) {
        return _buyCount >= _firstSellTaxAt ? _sellTax : _firstSellTax;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (swapEnabled && isLimited && _openTrade.add(_maxAt) < block.number) {
            removeLimits();
        }

        if (from == owner() || to == owner()) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 taxAmount = 0;
        if (from == pair && !_isExcludedFromFee[to]) {
            taxAmount = amount.mul(sellTax()).div(100);
        } else if (to == pair && !_isExcludedFromFee[from]) {
            taxAmount = amount.mul(sellTax()).div(100);
        }

        if (transferDelay) {
            if (to != address(router) && to != address(pair)) {
                require(_lastTransfer[tx.origin] < block.number, "transfer delay");
                _lastTransfer[tx.origin] = block.number;
            }
        }

        if (from == pair && to != address(router) && !_isExcludedFromFee[to]) {
            require(amount <= maxBuy && balanceOf(to).add(amount) <= maxWallet, "can not buy");
            _buyCount++;
        }

        uint256 swapAmount = balanceOf(address(this));
        if (
            !inSwap
                && to == pair
                && swapEnabled
                && swapAmount > _swapThreshold
                && _buyCount > _swapAt
        ) {
            swapTokensForEth(min(amount, min(swapAmount , _swapMax)));
            uint256 ethAmount = address(this).balance;
            if(ethAmount > 0) {
                _taxWallet.transfer(ethAmount);
            }
        }

        if(taxAmount > 0) {
            super._transfer(from, address(this), taxAmount);
        }
        super._transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() private {
        maxBuy = _supply;
        maxWallet = _supply;
        transferDelay = false;
        isLimited = false;
    }

    function openTrade() external onlyOwner() {
        require(pair == address(0), "trading is already open");
        _approve(address(this), address(router), _supply);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,0,
            owner(),
            block.timestamp);
        IERC20(pair).approve(address(router), type(uint).max);
        swapEnabled = true;
        _openTrade = block.number;
    }

    receive() external payable {}

    function manualSwap() external {
        require(msg.sender == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0) {
            _taxWallet.transfer(ethBalance);
        }
    }
}