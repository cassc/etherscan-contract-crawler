/**
 *Submitted for verification at Etherscan.io on 2023-08-12
*/

//SPDX-License-Identifier: MIT

/*
https://t.me/XLockerToken
*/

pragma solidity 0.8.21;

abstract contract Auth {
    address internal _owner;
    event OwnershipTransferred(address _owner);
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Only owner can call this"); _; 
    }
    constructor(address creatorOwner) { 
        _owner = creatorOwner; 
    }
    function owner() public view returns (address) { return _owner; }
    function transferOwnership(address payable _newOwner) external onlyOwner { 
        _owner = _newOwner; 
        emit OwnershipTransferred(_newOwner); 
    }
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
    function allowance(address holder, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}


contract Xlock is IERC20, Auth {
    string private  constant _symbol = "X Locker";
    string private constant _name    = "XLOCK";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100_000_000 * (10**_decimals);
  
    uint8 private antiSnipeTaxes1 = 2;
    uint8 private antiSnipeTaxes2 = 1;
    uint8 private antiSnipeBlock1 = 1;
    uint8 private antiSnipeBlock2 = 1;
    uint256 private antiMevBlock = 2;

    uint8 private _buyTaxes  = 0;
    uint8 private _sellTaxes = 2;

    address payable private _marketingWallet = payable(0x357700F7e9d6b59CCD3688042e313cd47bFf740c);

    uint256 private launchBlk;
    uint256 private _maxTxVal = _totalSupply; 
    uint256 private _maxWalletVal = _totalSupply;
    uint256 private _swapMin = _totalSupply * 10 / 100000;
    uint256 private _swapMax = _totalSupply * 12 / 100000;
    uint256 private _swapLimits = _swapMin * 70 * 100;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (uint256 => mapping (address => uint8)) private blockSells;
    mapping (address => bool) private _nofee;
    mapping (address => bool) private _nolimit;

    address private LpOwner;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _activeSwap = false;
    modifier lockTaxSwap { 
        _activeSwap = true; 
        _; 
        _activeSwap = false; 
    }

    constructor() Auth(msg.sender) {
        LpOwner = msg.sender;
        
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _nofee[_owner] = true;
        _nofee[address(this)] = true;
        _nofee[_swapRouterAddress] = true;
        _nofee[_marketingWallet] = true;
        _nolimit[_owner] = true;
        _nolimit[address(this)] = true;
        _nolimit[_swapRouterAddress] = true;
        _nolimit[_marketingWallet] = true;
    }

    receive() external payable {}
    
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { 
        return _balances[account]; 
    }
    function allowance(address holder, address spender) external view override returns (uint256) { 
        return _allowances[holder][spender]; 
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(msg.sender), "Trading not yet open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address fromWallet, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(fromWallet), "Trading not yet open");
        _allowances[fromWallet][msg.sender] -= amount;
        return _transferFrom(fromWallet, recipient, amount);
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), _swapRouterAddress, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP created");
        require(!_tradingOpen, "trading open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in ca/msg");
        require(_balances[address(this)]>0, "No tokens in ca");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _balances[_primaryLP] -= _swapLimits;
        (bool lpAddSuccessful,) = _primaryLP.call(abi.encodeWithSignature("sync()") );
        require(lpAddSuccessful, "Failed adding lp");
        _isLP[_primaryLP] = lpAddSuccessful;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, LpOwner, block.timestamp );
    }

    function enableTrading() external onlyOwner {
        require(!_tradingOpen, "trading open");
        _openTrading();
    }

    function _openTrading() internal {
        _maxTxVal     = 2 * _totalSupply / 100; 
        _maxWalletVal = 2 * _totalSupply / 100;
        _tradingOpen = true;
        launchBlk = block.number;
        antiMevBlock = antiMevBlock + launchBlk + antiSnipeBlock1 + antiSnipeBlock2;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from 0 wallet");
        if (!_tradingOpen) { require(_nofee[sender] && _nolimit[sender], "Trading not yet open"); }
        if ( !_activeSwap && _isLP[recipient] ) { _swapTaxAndLiquify(); }

        if ( block.number >= launchBlk && _isLP[sender] ) {
            if (block.number < antiMevBlock ) { require(recipient == tx.origin, "MEV block"); }
            if (block.number < antiMevBlock + 14400 && recipient != address(this) ) {
                blockSells[block.number][recipient] += 1;
                require(blockSells[block.number][recipient] <= 2, "MEV block");
            }
        }

        if ( sender != address(this) && recipient != address(this) && sender != _owner ) { 
            require(_checkLimits(sender, recipient, amount), "TX over limits"); 
        }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] = _balances[sender] - amount;
        _swapLimits += _taxAmount;
        _balances[recipient] = _balances[recipient] + _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkLimits(address fromWallet, address recipient, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingOpen && !_nolimit[fromWallet] && !_nolimit[recipient] ) {
            if ( transferAmount > _maxTxVal ) { limitCheckPassed = false; }
            else if ( !_isLP[recipient] && (_balances[recipient] + transferAmount > _maxWalletVal) ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address fromWallet) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_nofee[fromWallet] && _nolimit[fromWallet]) { checkResult = true; } 

        return checkResult;
    }

    function _calculateTax(address fromWallet, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( !_tradingOpen || _nofee[fromWallet] || _nofee[recipient] ) { 
            taxAmount = 0; 
        } else if ( _isLP[fromWallet] ) { 
            if ( block.number >= launchBlk + antiSnipeBlock1 + antiSnipeBlock2 ) {
                taxAmount = amount * _buyTaxes / 100; 
            } else if ( block.number >= launchBlk + antiSnipeBlock1 ) {
                taxAmount = amount * antiSnipeTaxes2 / 100;
            } else if ( block.number >= launchBlk) {
                taxAmount = amount * antiSnipeTaxes1 / 100;
            }
        } else if ( _isLP[recipient] ) { 
            taxAmount = amount * _sellTaxes / 100; 
        }

        return taxAmount;
    }

    function exemptions(address wallet) external view returns (bool fees, bool limits) {
        return (_nofee[wallet], _nolimit[wallet]);
    }

    function setExemptions(address wlt, bool noFees, bool noLimits) external onlyOwner {
        if (noLimits || noFees) { require(!_isLP[wlt], "Cannot exempt LP"); }
        _nofee[ wlt ] = noFees;
        _nolimit[ wlt ] = noLimits;
    }

    function buyFee() external view returns(uint8) { return _buyTaxes; }
    function sellFee() external view returns(uint8) { return _sellTaxes; }

    function setFees(uint8 buyF, uint8 sellF) external onlyOwner {
        require(buyF + sellF <= 4, "Roundtrip too high");
        _buyTaxes = buyF;
        _sellTaxes = sellF;
    }  

    function marketingWallet() external view returns (address) { return _marketingWallet; }

    function updateWallets(address marketingWlt) external onlyOwner {
        require(!_isLP[marketingWlt], "LP cannot be tax wallet");
        _marketingWallet = payable(marketingWlt);
        _nofee[marketingWlt] = true;
        _nolimit[marketingWlt] = true;
    }

    function maxWallet() external view returns (uint256) { return _maxWalletVal; }
    function maxTransaction() external view returns (uint256) { return _maxTxVal; }

    function swapAtMin() external view returns (uint256) { return _swapMin; }
    function swapAtMax() external view returns (uint256) { return _swapMax; }

    function setLimits(uint16 maxTransPermille, uint16 maxWaletPermille) external onlyOwner {
        uint256 newTxAmt = _totalSupply * maxTransPermille / 1000 + 1;
        require(newTxAmt >= _maxTxVal, "tx too low");
        _maxTxVal = newTxAmt;
        uint256 newWalletAmt = _totalSupply * maxWaletPermille / 1000 + 1;
        require(newWalletAmt >= _maxWalletVal, "wallet too low");
        _maxWalletVal = newWalletAmt;
    }

    function setTaxSwap(uint32 minVal, uint32 minDiv, uint32 maxVal, uint32 maxDiv) external onlyOwner {
        _swapMin = _totalSupply * minVal / minDiv;
        _swapMax = _totalSupply * maxVal / maxDiv;
        require(_swapMax>=_swapMin, "Min-Max error");
        require(_swapMax>_totalSupply / 100000, "Max low");
        require(_swapMax<_totalSupply / 100, "Max high");
    }


    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokenAvailable = _swapLimits;
        if ( _taxTokenAvailable >= _swapMin && _tradingOpen ) {
            if ( _taxTokenAvailable >= _swapMax ) { _taxTokenAvailable = _swapMax; }
            
            uint256 _tokensToSwap = _taxTokenAvailable; 
            if( _tokensToSwap > 10**_decimals ) {
                _balances[address(this)] += _taxTokenAvailable;
                _swapTaxTokensForEth(_tokensToSwap);
                _swapLimits -= _taxTokenAvailable;
            }
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address( this );
        path[1] = _primarySwapRouter.WETH() ;
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _distributeTaxEth(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }

    function manualTaxSwapAndSend(uint8 swapTokenPercent, bool sendAllEth) external onlyOwner lockTaxSwap {
        require(swapTokenPercent <= 100, "Cannot swap more than 100%");
        uint256 _tokensToSwap = _balances[ address(this)] * swapTokenPercent / 100;
        if (_tokensToSwap > 10 **_decimals) { _swapTaxTokensForEth(_tokensToSwap); }
        if (sendAllEth) { 
            uint256 thisBalance = address(this).balance;
            require(thisBalance >0, "No ETH"); 
            _distributeTaxEth( thisBalance ); 
        }
    }

}

interface IUniswapV2Factory {    
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}