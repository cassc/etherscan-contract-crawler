/**
 *Submitted for verification at Etherscan.io on 2023-09-27
*/

//SPDX-License-Identifier: MIT

/*
 https://t.me/XEyeApp
 https://x.com/XEyeApp
 https://XEye.pro 
*/

pragma solidity 0.8.21;


abstract contract Auth {
    address internal _owner;
    constructor(address creator_Owner) { 
        _owner = creator_Owner; 
    }
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Only owner can call this."); _; 
    }
    function owner() public view returns (address) { 
        return _owner; 
    }
    function transferOwnership(address payable newOwner) external onlyOwner { 
        _owner = newOwner; 
        emit OwnershipTransferred(newOwner); 
    }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0); 
        emit OwnershipTransferred(address(0)); 
    }
    event OwnershipTransferred(address _owner);
}

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

contract Xeye is IERC20, Auth {
    uint8 private constant _decim    = 9;
    uint256 private constant _totSup = 21000000000  * (10**_decim);
    string private constant _name    = "X Eye";
    string private constant _symbol  = "XEYE";

    uint8 private _buyTaxRate  = 2;
    uint8 private _sellTaxRate = 2;
    address payable private _walletMarketing = payable(0xa3F69574FD9b305d1F7c76629D46E521eFCAf101); 

    uint256 private _maxTxAmount     = _totSup; 
    uint256 private _maxWalletAmount = _totSup;
    uint256 private _taxSwpMin = _totSup * 10 / 100000;
    uint256 private _taxSwpMax = _totSup * 67 / 100000;
    uint256 private _swapLimit = _taxSwpMin * 60 * 100;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFee;
    mapping (address => bool) private _noLimit;

    address private constant _swapRouterAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddr);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true;  _; 
        _inTaxSwap = false; 
    }

    constructor() Auth(msg.sender) {
        _balances[address(_owner)] = _totSup;
        emit Transfer(address(0), address(_owner), _balances[address(_owner)]);

        _noFee[_owner] = true;
        _noFee[address(this)] = true;
        _noFee[_swapRouterAddr] = true;
        _noFee[_walletMarketing] = true;
        _noLimit[_owner] = true;
        _noLimit[address(this)] = true;
        _noLimit[_swapRouterAddr] = true;
        _noLimit[_walletMarketing] = true;
    }

    receive() external payable {}
    
    function totalSupply() external pure override returns (uint256) { return _totSup; }
    function decimals() external pure override returns (uint8) { return _decim; }
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
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(sender), "Trading not open");
        _allowances[sender][msg.sender] -= amount;
        return _transfer(sender, recipient, amount);
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_swapRouterAddr] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddr] = type(uint256).max;
            emit Approval(address(this), _swapRouterAddr, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP exists");
        require(!_tradingOpen, "trading already open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance, false);
        _balances[_primaryLP] -= _swapLimit;
        (bool lpAddSucc,) = _primaryLP.call(abi.encodeWithSignature("sync()"));
        require(lpAddSucc, "Failed adding liquidity");
        _isLP[_primaryLP] = lpAddSucc;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
        address lpTokenRecipient = _owner;
        if ( autoburn ) { lpTokenRecipient = address(0); }
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
    }

    function enableTrading() external onlyOwner {
        _openTrading();
    }

    function _openTrading() internal {
        require(!_tradingOpen, "trading already open");
        _maxTxAmount     = _totSup * 2 / 100; 
        _maxWalletAmount = _totSup * 2 / 100;
        _tradingOpen = true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!_tradingOpen) { require(_noFee[sender] && _noLimit[sender], "Trading not open"); }
        if ( !_inTaxSwap && _isLP[recipient] && !_noFee[sender]) { _swapTaxAndLiquify(); }
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

    function _checkLimits(address sender, address recipient, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingOpen && !_noLimit[sender] && !_noLimit[recipient] ) {
            if ( transferAmount > _maxTxAmount ) { limitCheckPassed = false; }
            else if ( !_isLP[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmount) ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFee[sender] && _noLimit[sender]) { checkResult = true; } 
        return checkResult;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        if ( !_tradingOpen || _noFee[sender] || _noFee[recipient] ) { taxAmount = 0; } 
        else if ( _isLP[sender] ) { taxAmount = amount * _buyTaxRate / 100; } 
        else if ( _isLP[recipient] ) { taxAmount = amount * _sellTaxRate / 100; }
        return taxAmount;
    }

    function exempt(address wallet) external view returns (bool fees, bool limits) {
        return (_noFee[wallet],_noLimit[wallet]);
    }
    function setExempt(address wallet, bool noFees, bool noLimits) external onlyOwner {
        if (noLimits || noFees) { require(!_isLP[wallet], "Cannot exempt LP"); }
        _noFee[ wallet ] = noFees;
        _noLimit[ wallet ] = noLimits;
    }

    function buyFee() external view returns(uint8) {
        return _buyTaxRate;
    }
    function sellFee() external view returns(uint8) {
        return _sellTaxRate;
    }

    function setFees(uint8 buy, uint8 sell) external onlyOwner {
        require(buy + sell <= 4, "Roundtrip too high");
        _buyTaxRate = buy;
        _sellTaxRate = sell;
    }  

    function marketingWallet() external view returns (address) {
        return _walletMarketing;
    }

    function updateWallets(address marketing) external onlyOwner {
        require(!_isLP[marketing], "LP cannot be tax wallet");
        _walletMarketing = payable(marketing);
        _noFee[marketing] = true;
        _noLimit[marketing] = true;
    }

    function maxWallet() external view returns (uint256) {
        return _maxWalletAmount;
    }
    function maxTransaction() external view returns (uint256) {
        return _maxTxAmount;
    }

    function setLimits(uint16 maxTransactionPermille, uint16 maxWalletPermille) external onlyOwner {
        uint256 newTxAmt = _totSup * maxTransactionPermille / 1000 + 1;
        require(newTxAmt >= _maxTxAmount, "tx too low");
        _maxTxAmount = newTxAmt;
        uint256 newWalletAmt = _totSup * maxWalletPermille / 1000 + 1;
        require(newWalletAmt >= _maxWalletAmount, "wallet too low");
        _maxWalletAmount = newWalletAmt;
    }

    function setTaxSwap(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
        _taxSwpMin = _totSup * minValue / minDivider;
        _taxSwpMax = _totSup * maxValue / maxDivider;
        require(_taxSwpMax>=_taxSwpMin, "Min/Max error");
        require(_taxSwpMax>_totSup / 100000, "Max too low");
        require(_taxSwpMax<_totSup / 100, "Max too high");
    }


    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = _swapLimit;
        if ( _taxTokensAvailable >= _taxSwpMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwpMax ) { _taxTokensAvailable = _taxSwpMax; }
            uint256 _tokensToSwap = _taxTokensAvailable;
            if( _tokensToSwap > 10**_decim ) {
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
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _distributeTaxEth(uint256 amount) private {
        _walletMarketing.transfer(amount);
    }

    function manualSwap() external onlyOwner lockTaxSwap {
        _swapTaxTokensForEth(_balances[address(this)]);
        _distributeTaxEth(address(this).balance); 
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