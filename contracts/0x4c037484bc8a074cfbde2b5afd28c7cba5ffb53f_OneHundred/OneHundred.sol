/**
 *Submitted for verification at Etherscan.io on 2023-07-14
*/

//SPDX-License-Identifier: MIT

/*
https://t.me/The100Token
*/

pragma solidity 0.8.20;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint256 amountIn,
        uint256 amountOutMin, address[] calldata path,
        address to, uint256 deadline ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(address token,
        uint256 amountTokenDesired, uint256 amountTokenMin,
        uint256 amountETHMin, address to,
        uint256 deadline )
        external payable
        returns (
            uint256 amountToken, uint256 amountETH, uint256 liquidity
        );
}

abstract contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this"); _;
    }

    constructor(address creatorOwner) { owner = creatorOwner;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        owner = newOwner; emit OwnershipTransferred(newOwner);
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0); emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
}

contract OneHundred is IERC20, Ownable {
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 100 * (10**_decimals);
    string private constant _name = "100 Token";
    string private constant _symbol = "100";
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private blacklisted;
    mapping(address => uint256) private _balances;

    uint256 private _maxWalletAmount = _totalSupply;

    uint256 private _maxTxAmount = _totalSupply;
    mapping(address => bool) private _noLimits;
    uint256 private _launchBlock;

    uint256 antiSniperMevBlock;
    
    uint256 blacklistBlock;

    bool private tradingOpen;

    address private liquidityProvider;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping(address => bool) private _isLP;

    

    bool private _inTaxSwap = false;
    modifier lockTaxSwap() {
        _inTaxSwap = true; _;
        _inTaxSwap = false; }

    constructor() Ownable(msg.sender) {
        _balances[owner] = (_totalSupply * 0) / 100;
        emit Transfer(address(0), owner, _balances[owner]);

        _balances[address(this)] = _totalSupply - _balances[owner];
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _noLimits[owner] = true;
        _noLimits[address(this)] = true;
        _noLimits[_swapRouterAddress] = true;
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        require(_checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(_checkTradingOpen(sender), "Trading not open");
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if (_allowances[address(this)][_swapRouterAddress] < _tokenAmount) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), _swapRouterAddress, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP exists");
        require(!tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance > 0,
            "No ETH in contract or message" );
        require(_balances[address(this)] > 0, "No tokens in contract");
        liquidityProvider = msg.sender;
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(
            address(this), _primarySwapRouter.WETH()
        );
        _addLiquidity(_balances[address(this)], address(this).balance, false);
        _isLP[_primaryLP] = true;
        _openTrading();
    }

    function _addLiquidity( uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn
    ) internal {
        address lpTokenRecipient = liquidityProvider;
        if (autoburn) { lpTokenRecipient = address(0);
        }
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei}
        (
            address(this), _tokenAmount, 
            0, 0,
            lpTokenRecipient, block.timestamp
        );
    }

    function _openTrading() internal {
        require(!tradingOpen, "already open");
        _maxTxAmount = ((_totalSupply * 1) / 100) + 10**9;
        _maxWalletAmount = ((_totalSupply * 1) / 100) + 10**9;
        tradingOpen = true;
        _launchBlock = block.number;
        blacklistBlock = block.number + 10;
        antiSniperMevBlock = block.number + 20;
    }

    function blacklistSnipers(address wallet) private 
    {
        if ( wallet != _primaryLP &&
            wallet != owner && wallet != address(this) &&
            wallet != _swapRouterAddress ) {
            blacklisted[wallet] = true; }
    }

    function _transferFrom( address sender, address recipient, uint256 amount
    ) internal returns (bool) 
    {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!tradingOpen) { require(_noLimits[sender], "Trading not open");
        } else if (_isLP[sender]) {
            if (block.number <= blacklistBlock) { blacklistSnipers(recipient);
            } else if (block.number < antiSniperMevBlock) { require(recipient == tx.origin, "Sniper MEV blocked"); }
        } else { require(!blacklisted[sender], "Wallet blacklisted");
        }

        if ( sender != address(this) && recipient != address(this) && sender != owner
        ) { require(_checkLimits(sender, recipient, amount),"TX exceeds limits");
        }

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkLimits(
        address sender, address recipient, uint256 transferAmount
    ) internal view returns (bool) 
    {
        bool limitCheckPassed = true;
        if (tradingOpen && !_noLimits[sender] && !_noLimits[recipient]) {
            if (transferAmount > _maxTxAmount) { limitCheckPassed = false;
            } else if ( !_isLP[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmount) ) 
            { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address sender) private view returns (bool) {
        bool checkResult = false;
        if (tradingOpen) { checkResult = true;
        } else if (_noLimits[sender]) { checkResult = true;
        }
        return checkResult;
    }

    function isUnlimited(address awallet) external view returns (bool limits) { 
        return (_noLimits[awallet]);
    }

    function isBlacklisted(address awallet) external view returns (bool limits) {
        return (blacklisted[awallet]);
    }

    function setUnlimited(address awallet, bool noLimits) external onlyOwner {
        if (noLimits) { require(!_isLP[awallet], "Cannot exempt LP"); }
        _noLimits[awallet] = noLimits;
    }

    function maxWallet() external view returns (uint256) { return _maxWalletAmount; }

    function maxTransaction() external view returns (uint256) { return _maxTxAmount; }

    function setLimits(uint16 maxTransactionPermille, uint16 maxWalletPermille)
        external onlyOwner
    {
        uint256 newTxAmt = ((_totalSupply * maxTransactionPermille) / 1000) + 10**9;
        require(newTxAmt >= _maxTxAmount, "tx too low");
        _maxTxAmount = newTxAmt;
        uint256 newWalletAmt = ((_totalSupply * maxWalletPermille) / 1000) + 10**9;
        require(newWalletAmt >= _maxWalletAmount, "wallet too low");
        _maxWalletAmount = newWalletAmt;
    }
}