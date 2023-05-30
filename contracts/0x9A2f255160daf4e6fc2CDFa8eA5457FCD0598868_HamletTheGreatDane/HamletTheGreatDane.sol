/**
 *Submitted for verification at Etherscan.io on 2023-04-09
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-09
*/

/*

Hamlet the Great Dane - $HMLT

https://t.me/HAMLETREBORN
https://twitter.com/DaneNamedHamlet

*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

contract HamletTheGreatDane is IERC20, Auth {
    string private constant _name         = "Hamlet The Great Dane";
    string private constant _symbol       = "HAMLET";
    uint8 private constant _decimals      = 9;
    uint256 private constant _totalSupply = 1_000_000_000_000 * (10**_decimals);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint32 private _tradeCount;

    address payable private constant _walletMarketing = payable(0xb0D4501B57467c1Aa13708808333dbCEB2D41b02);
    uint256 private constant _taxSwapMin = _totalSupply / 200000;
    uint256 private constant _taxSwapMax = _totalSupply / 1000;

    mapping (address => bool) private _noFees;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);

    constructor() Auth(msg.sender) {
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _balances[_owner]);

        _noFees[_owner] = true;
        _noFees[address(this)] = true;
        _noFees[_swapRouterAddress] = true;
        _noFees[_walletMarketing] = true;
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
        _tradeCount = 0;
        _tradingOpen = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        require(sender != address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B), "Vitalik NEVER SELLING");  // Tokens in VB wallet are burned

        if (!_tradingOpen) { require(_noFees[sender], "Trading not open"); }
        if ( !_inTaxSwap && _isLP[recipient] ) { _swapTaxAndLiquify(); }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount; 
            incrementTradeCount();
        }
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function incrementTradeCount() private {
        if ( _tradeCount <= 1_000_001 ) {
            // tax is finalized after 1,000,000 trades
            _tradeCount += 1;
        } 
    }

    function tax() external view returns (uint32 taxNumerator, uint32 taxDenominator) {
        (uint32 numerator, uint32 denominator) = _getTaxPercentages();
        return (numerator, denominator);
    }

    function _getTaxPercentages() private view returns (uint32 numerator, uint32 denominator) {
        uint32 taxNumerator;
        uint32 taxDenominator = 100_000;

        if ( _tradeCount <= 20_000 ) {
            taxNumerator = 2000;    // up to 20,000 trades the tax is 3.0 %
        } else if ( _tradeCount <= 100_000 ) {
            taxNumerator = 1000;    // from 20,001 to 100,000 trades the tax is 1.0 %
        } else {
            taxNumerator = 225;     // above 100,000 trades the tax is 0.225 %
        }

        return (taxNumerator, taxDenominator);
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( _tradingOpen && !_noFees[sender] && !_noFees[recipient] ) { 
            if ( _isLP[sender] || _isLP[recipient] ) {
                (uint32 numerator, uint32 denominator) = _getTaxPercentages();
                taxAmount = amount * numerator / denominator;
            }
        }

        return taxAmount;
    }

    function marketingMultisig() external pure returns (address) {
        return _walletMarketing;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            uint256 _tokensForLP = 0;
            if ( _tradeCount < 100_000 ) {
                // before 100,000 trades are reached half of the tax goes to LP
                _tokensForLP = _taxTokensAvailable / 4;
            }
            
            uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP;
            if( _tokensToSwap > 10**_decimals ) {
                uint256 _ethPreSwap = address(this).balance;
                _swapTaxTokensForEth(_tokensToSwap);
                uint256 _ethSwapped = address(this).balance - _ethPreSwap;
                if ( _tokensForLP > 0 ) {
                    uint256 _ethWeiAmount = _ethSwapped / 2 ;
                    _approveRouter(_tokensForLP);
                    _addLiquidity(_tokensForLP, _ethWeiAmount);
                }
            }
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { 
                (bool sent, bytes memory data) = _walletMarketing.call{value: _contractETHBalance}("");
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

    function airdrop(address[] calldata addresses, uint256[] calldata tokenAmounts) external onlyOwner {
        require(addresses.length <= 250,"More than 250 wallets");
        require(addresses.length == tokenAmounts.length,"List length mismatch");

        uint256 airdropTotal = 0;
        for(uint i=0; i < addresses.length; i++){
            airdropTotal += (tokenAmounts[i] * 10**_decimals);
        }
        require(_balances[msg.sender] >= airdropTotal, "Token balance too low");

        for(uint i=0; i < addresses.length; i++){
            _balances[msg.sender] -= (tokenAmounts[i] * 10**_decimals);
            _balances[addresses[i]] += (tokenAmounts[i] * 10**_decimals);
            emit Transfer(msg.sender, addresses[i], (tokenAmounts[i] * 10**_decimals) );       
        }

        emit TokensAirdropped(addresses.length, airdropTotal);
    }
}