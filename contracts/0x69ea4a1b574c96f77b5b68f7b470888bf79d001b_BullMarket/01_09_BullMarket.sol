/**
 *Submitted for verification at Etherscan.io on 2023-10-05
*/

// SPDX-License-Identifier: MIT

/*
In today's financial landscape, where low trading volumes can often stagnate market potential, the BULLMARKET Token emerges as a beacon of momentum. 
Symbolized by the ticker $BOOST, this token isn't just named for the iconic market trend; it's a mission statement. 
We aim to rush through the prevailing quietude like a determined bull, amplifying activity and boosting the market for traders everywhere. 
Designed for the modern investor, $BOOST captures the essence of innovation and resilience in the digital asset space. 
Whether you're a seasoned trader or just starting, with $BOOST, you're poised to be part of a transformative movement. 
Dive in and experience the momentum with $BOOST - the token that propels markets forward!
*/


pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BullMarket is IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    string private constant _name = "BULLMARKET";
    string private constant _symbol = "$BOOST";
    uint256 private constant _decimals = 18;
    
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) private isExcludedFromTax;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    
    uint256 private _totalSupply = 1000000000*10**_decimals; 

    uint256 private _maxTxAmount = 20000000*10**_decimals; 
    uint256 private _maxWalletSize = 40000000*10**_decimals;
    uint256 private _taxSwapThreshold = 10000000*10**_decimals;
    uint256 private _maxTaxSwap = 10000000*10**_decimals;
    
    uint256 private _swapThreshold = 25;
    uint256 public _buyTax = 2; 
    uint256 public _sellTax = 2; 
    uint256 public _launchBuyTax = 20; 
    uint256 public _launchSellTax = 20;
    uint256 public _buyCount = 0;

    address payable public _taxWallet; 
    address public uniswapV2Pair;

    bool public tradingOpen = false;
    bool public taxEnabled = true;
    bool public swapEnabled = false;
    bool public transferDelayEnabled = true;
    bool private inSwap = false;
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    IUniswapV2Router02 private uniswapV2Router;    
    
    constructor() payable  {
        require(msg.value >= 1 ether, "Minimum 1 ether is required");

        _taxWallet = payable(_msgSender()); //Tax wallet

        isExcludedFromTax[address(uniswapV2Router)] = true;
        isExcludedFromTax[address(uniswapV2Pair)] = true;
        isExcludedFromTax[_msgSender()] = true;
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[_taxWallet] = true;  

        _balances[address(this)] = _totalSupply;   
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 tax = 0; 
        if(taxEnabled){
            //Only one purchase per block allowed.
            if (transferDelayEnabled) {
                  if (recipient != address(uniswapV2Router) && recipient != address(uniswapV2Pair)) {
                      require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer: Transfer Delay enabled. Only one purchase per block allowed.");
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            //Buy.
            if (sender == uniswapV2Pair && recipient != address(uniswapV2Router) && !isExcludedFromTax[recipient]) {
                    require(amount <= _maxTxAmount, "Exceeds the maxTxAmount.");
                    require(balanceOf(recipient) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                    tax = amount.mul((_buyCount > _swapThreshold) ? _buyTax : _launchBuyTax).div(100);
                    _buyCount++;
                }

            //Sell.
            if(recipient == uniswapV2Pair && sender != address(this) && !isExcludedFromTax[sender]) {
                    require(amount <= _maxTxAmount, "Exceeds the maxTxAmount.");
                    tax = amount.mul((_buyCount > _swapThreshold) ? _sellTax : _launchSellTax).div(100);
                }

            //Swap tax to ETH.
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && recipient == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _swapThreshold) {
                    swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                    uint256 contractETHBalance = address(this).balance;
                    if(contractETHBalance > 0) {
                        sendETHToTax(address(this).balance);
                    }
                } 
                
            //Remove limits automaticly after threshold is met.
            if (_buyCount == _swapThreshold) {
                removeLimits();
                }       
            }

            //Tax handover.
            if (tax > 0) {
                _balances[address(this)] = _balances[address(this)].add(tax);
                emit Transfer(sender, address(this), tax);
            }
        
        //Commit transaction.
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount.sub(tax));
        emit Transfer(sender, recipient, amount.sub(tax));
    }

    //Returns the smaller of the two values.
    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a > b) ? b : a;
    }
    
    //Will open the trading and fill LP.
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    //Makes sure contract can receive funds.
    receive() external payable {}
    
    //Enables base tax on transactions.
    function taxEnable() public onlyOwner {
        require(!taxEnabled,"tax is already enabled");
        taxEnabled = true;
    }

    //Disables base tax on transactions, used for marketing and promotions.
    function taxDisable() public onlyOwner {
        require(taxEnabled,"tax is already disabled");
        taxEnabled = false;
    }

    //Enables taxes for specified address.
    function IncludeInTax(address wallet, bool) public onlyOwner {
        isExcludedFromTax[wallet] = false;
    }

    //Disbles taxes for specified address.
    function ExcludedFromTax(address wallet, bool) public onlyOwner {
        isExcludedFromTax[wallet] = true;
    }

    //Send ETH to Tax.
    function sendETHToTax(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    //Swaps tokens for ETH.
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        require(tradingOpen, "trading is not yet open");
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

    //Removes limits of maxTx and maxWallet
    function removeLimits() private {
        _maxTxAmount = _totalSupply;
        _maxWalletSize = _totalSupply;
    }

    //Manually swap tokens for ETH.
    function manualSwap() external {
        require(_msgSender() ==_taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance > 0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0){
          sendETHToTax(ethBalance);
        }
    }
}