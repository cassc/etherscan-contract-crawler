/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

abstract contract Ownable {
    address public owner;

    constructor(address creatorOwner) {
        owner = creatorOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
}

contract Btc3 is IERC20, Ownable {
    uint8 private constant   _decimals    = 9;
    uint256 private constant _totalSupply = 21_000_000 * (10**_decimals);
    string private constant  _name        = "BTC 3.0";
    string private constant  _symbol      = "BTC3.0";

    uint8 private sniperBlacklistBlocks = 1;
    mapping(address => bool) private blacklisted;

    uint256 private _launchBlock;
    uint256 private _maxTxAmount = _totalSupply;
    uint256 private _maxWalletAmount = _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _noLimits;

    address private liquidityProvider;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping(address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap() {
        _inTaxSwap = true;
        _;
        _inTaxSwap = false;
    }

    constructor() Ownable(msg.sender) {
        _balances[owner] = _totalSupply * 0 / 100;
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
        require(!_tradingOpen, "trading is open");
        require(
            msg.value > 0 || address(this).balance > 0,
            "No ETH in contract or message"
        );
        require(_balances[address(this)] > 0, "No tokens in contract");
        liquidityProvider = msg.sender;
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(
            address(this),
            _primarySwapRouter.WETH()
        );
        _addLiquidity(_balances[address(this)], address(this).balance, false);
        _isLP[_primaryLP] = true;
        _openTrading();
    }

    function _addLiquidity(
        uint256 _tokenAmount,
        uint256 _ethAmountWei,
        bool autoburn
    ) internal {
        address lpTokenRecipient = liquidityProvider;
        if (autoburn) {
            lpTokenRecipient = address(0);
        }
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei}(
            address(this),
            _tokenAmount,
            0,
            0,
            lpTokenRecipient,
            block.timestamp
        );
    }

    function _openTrading() internal {
        _maxTxAmount     = _totalSupply * 1 / 100;
        _maxWalletAmount = _totalSupply * 1 / 100;
        _tradingOpen = true;
        _launchBlock = block.number;
    }
 
    function blacklistSniper(address wallet) private {
        if ( 
            wallet != _primaryLP && 
            wallet != owner && 
            wallet != address(this) && 
            wallet != _swapRouterAddress 
        ) {
            blacklisted[wallet] = true;
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!_tradingOpen) {
            require(_noLimits[sender], "Trading not open");
        } else {
            if ( block.number <= _launchBlock + sniperBlacklistBlocks ) {
                blacklistSniper(recipient);
            }
        }
        
        require(!blacklisted[sender], "Blacklisted wallet");

        if (
            sender != address(this) &&
            recipient != address(this) &&
            sender != owner
        ) {
            require(
                _checkLimits(sender, recipient, amount),
                "TX exceeds limits"
            );
        }

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkLimits(
        address sender,
        address recipient,
        uint256 transferAmount
    ) internal view returns (bool) {
        bool limitCheckPassed = true;
        if (_tradingOpen && !_noLimits[sender] && !_noLimits[recipient]) {
            if (transferAmount > _maxTxAmount) {
                limitCheckPassed = false;
            } else if (
                !_isLP[recipient] &&
                (_balances[recipient] + transferAmount > _maxWalletAmount)
            ) {
                limitCheckPassed = false;
            }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address sender) private view returns (bool) {
        bool checkResult = false;
        if (_tradingOpen) {
            checkResult = true;
        } else if (_noLimits[sender]) {
            checkResult = true;
        }

        return checkResult;
    }

    function isUnlimited(address wallet) external view returns (bool limits) {
        return (_noLimits[wallet]);
    }

    function isBlacklisted(address wallet) external view returns (bool limits) {
        return (blacklisted[wallet]);
    }

    function setUnlimited(
        address wallet,
        bool noLimits
    ) external onlyOwner {
        if (noLimits) {
            require(!_isLP[wallet], "Cannot exempt LP");
        }
        _noLimits[wallet] = noLimits;
    }


    function maxWallet() external view returns (uint256) {
        return _maxWalletAmount;
    }

    function maxTransaction() external view returns (uint256) {
        return _maxTxAmount;
    }

    function setLimits(uint16 maxTransactionPermille, uint16 maxWalletPermille)
        external
        onlyOwner
    {
        uint256 newTxAmt = (_totalSupply * maxTransactionPermille) / 1000 + 1;
        require(newTxAmt >= _maxTxAmount, "tx too low");
        _maxTxAmount = newTxAmt;
        uint256 newWalletAmt = (_totalSupply * maxWalletPermille) / 1000 + 1;
        require(newWalletAmt >= _maxWalletAmount, "wallet too low");
        _maxWalletAmount = newWalletAmt;
    }
}