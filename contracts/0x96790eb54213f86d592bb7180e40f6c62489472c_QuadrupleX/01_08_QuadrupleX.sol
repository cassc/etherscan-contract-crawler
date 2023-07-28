/*        

____________/\\\_____/\\\_______/\\\_        
 __________/\\\\\____\///\\\___/\\\/__       
  ________/\\\/\\\______\///\\\\\\/____      
   ______/\\\/\/\\\________\//\\\\______     
    ____/\\\/__\/\\\_________\/\\\\______    
     __/\\\\\\\\\\\\\\\\______/\\\\\\_____   
      _\///////////\\\//_____/\\\////\\\___  
       ___________\/\\\_____/\\\/___\///\\\_ 
        ___________\///_____\///_______\///__

Website: https://xxxxstrewth.com
Telegram: https://t.me/xxxxstrewth
Twitter: https://twitter.com/HOPPYToken

*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";


contract QuadrupleX is Context, IERC20, Ownable {
    using Address for address payable;
    using SafeMath for uint;

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint) private _holderLastTransferTimestamp;

    address payable private _taxWallet;

    uint private _initialBuyTax = 40;
    uint private _initialSellTax = 40;
    uint private _finalBuyTax = 1;
    uint private _finalSellTax = 1;
    uint private _reduceBuyTaxAfter = 20;
    uint private _reduceSellTaxAfter = 20;
    uint private _preventSwapBefore = 20;

    uint8 private constant _decimals = 8;
    uint private constant _tTotal = 26439111 * 10**_decimals;
    string private constant _name = unicode"4X";
    string private constant _symbol = unicode"XXXX";

    uint public _maxTxAmount = _tTotal / 100;
    uint public _maxWalletSize = _tTotal / 100;
    uint public _swapThreshold = _tTotal / 1000;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private tradingOpen;
    uint public launchBlock;

    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }


    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint taxAmount;

        if (from != owner() && to != owner()) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }

            taxAmount = amount.mul((block.number > launchBlock + _reduceBuyTaxAfter) ? _finalBuyTax : _initialBuyTax).div(100);
            if (to == uniswapV2Pair && from != address(this)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((block.number > launchBlock + _reduceSellTaxAfter) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _swapThreshold && block.number > launchBlock + _preventSwapBefore) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _swapThreshold.mul(5))));
                uint contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint a, uint b) private pure returns (uint) {
      return (a > b) ? b : a;
    }

    function swapTokensForEth(uint tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) return;
        if (!tradingOpen) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint amount) private {
        Address.sendValue(payable(_taxWallet), amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already open");

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        swapEnabled = true;
        tradingOpen = true;
        launchBlock = block.number;
    }

    function manualSwap() external {
        require(_msgSender() == _taxWallet);

        uint tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }

        uint ethBalance = address(this).balance;
        if (ethBalance > 0) {
          sendETHToFee(ethBalance);
        }
    }

    receive() external payable {}
}