/**
 *Submitted for verification at Etherscan.io on 2023-08-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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

contract Nasdaq is IERC20, Auth {
    string private constant _name         = "NASDAQ4200";
    string private constant _symbol       = "NASDAQ";
    uint8 private constant _decimals      = 18;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);

    uint256 private _initialBuyTax=15;
    uint256 private _initialSellTax=42;
    uint256 private _midSellTax=15;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 public _reduceBuyTaxAt=69;
    uint256 public _reduceSellTax1At=100;
    uint256 public _reduceSellTax2At=420;
    uint256 private _preventSwapBefore=30;
    uint256 public _buyCount=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isBlackListed;
    mapping (address => bool) private isWhitelisted;
    mapping (address => bool) private _noFees;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    address payable private _walletTax;
    uint256 private constant _taxSwapMin = _totalSupply / 200000;
    uint256 private constant _taxSwapMax = _totalSupply / 500;
  
    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxHoldingAmount = 20_000_001 * (10**_decimals); // 2%
    uint256 public minHoldingAmount = 100_000 * (10**_decimals); // 0.01%;
    
    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    constructor(address[] memory _users) Auth(msg.sender) { 

        _balances[msg.sender] = (_totalSupply / 1000 ) * 42;
        _balances[address(this)] = (_totalSupply / 1000 ) * 958;

        emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
        
        setTaxWallet(msg.sender);
        setWhitelist(_users, true);

        _walletTax = payable(msg.sender);
        _noFees[_walletTax] = true;
        _noFees[_owner] = true;
        _noFees[address(this)] = true;
  
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        require(!isBlackListed[sender], "Sender Blacklisted");
        require(!isBlackListed[recipient], "Receiver Blacklisted");

        if (!_tradingOpen) { require(_noFees[sender], "Trading not open"); }
        if ( !_inTaxSwap && _isLP[recipient] && _buyCount >= _preventSwapBefore) { _swapTaxAndLiquify(); }

        if (limited && sender == _primaryLP) {
            require(balanceOf(recipient) + amount <= maxHoldingAmount && balanceOf(recipient) + amount >= minHoldingAmount, "Forbid");
            require(isWhitelisted[sender] || isWhitelisted[recipient], "Forbid");
        }

        if (transferDelayEnabled) {
            if (recipient != _swapRouterAddress && recipient != _primaryLP) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount; 
        }

        if(sender == _swapRouterAddress){
            _buyCount++;
        }

        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
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
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[_primaryLP] = true;
        _tradingOpen = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function setTaxWallet(address newTaxWallet) public onlyOwner {
        _walletTax = payable(newTaxWallet);
    }

    function setBlackList(address[] memory _users, bool set) public onlyOwner {
        for(uint256 i = 0; i < _users.length; i++){
            isBlackListed[_users[i]] = set;
        }
    }

    function setWhitelist(address[] memory _users, bool set) internal {
        for(uint256 i = 0; i < _users.length; i++){
            isWhitelisted[_users[i]] = set;
        }
    }

    function removeLimits() external onlyOwner{
        limited = false;
        _reduceSellTax1At=20;
        _reduceSellTax2At=20;
        _reduceBuyTaxAt=20;
        transferDelayEnabled=false;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {

        uint256 taxAmount;
        if ( _tradingOpen && !_noFees[sender] && !_noFees[recipient] ) { 
            if ( _isLP[sender] || _isLP[recipient] ) {
                taxAmount = (amount / 100) * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);

                if(recipient == _primaryLP && sender != address(this)){

                    uint256 taxRate;
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

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 
                bool success;
                (success,) = _walletTax.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
}