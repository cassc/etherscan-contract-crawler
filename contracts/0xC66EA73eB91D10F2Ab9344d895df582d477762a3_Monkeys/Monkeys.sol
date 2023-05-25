/**
 *Submitted for verification at Etherscan.io on 2023-05-17
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
        address indexed _owner,
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

abstract contract Auth {
    address internal _owner;
    event OwnershipTransferred(address _owner);

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

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(address(0));
    }
}

contract Monkeys is IERC20, Auth {
    string private constant _name = "Monkeys";
    string private constant _symbol = "Monkeys";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 500_000_000_000 * (10**_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint32 private taxValue = 1000;

    address payable private constant _walletMarketing =
        payable(0x627a2196b244857E40c4e5d1D73BB48d511Bf2B6);
    uint256 private constant _taxSwapMin = _totalSupply / 200000;
    uint256 private constant _taxSwapMax = _totalSupply / 1000;

    mapping(address => bool) private _noFees;

    uint256 private startBlock;
    mapping(address => bool) private _isBot;

    address private constant _swapRouterAddress =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IUniswapV2Router02 private _primarySwapRouter =
        IUniswapV2Router02(_swapRouterAddress);

    address public _primaryLP;
    mapping(address => bool) private _isLP;

    bool public autoTrading = false;
    bool public _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap() {
        _inTaxSwap = true;
        _;
        _inTaxSwap = false;
    }

    constructor() Auth(msg.sender) {
        address receiver = address(0x592dE0eaBE4747106E2F2A0597596c446662CD2d);
        _balances[receiver] = _totalSupply;
        emit Transfer(address(0), receiver, _balances[receiver]);

        _noFees[receiver] = true;
        _noFees[address(this)] = true;
        _noFees[_swapRouterAddress] = true;
        _noFees[_walletMarketing] = true;
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
        require(_checkTradingOpen(msg.sender, recipient), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(_checkTradingOpen(sender, recipient), "Trading not open");
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

    function addLP(address _lp) external onlyOwner {
        _isLP[_lp] = true;
    }

    function removeLP(address _lp) external onlyOwner {
        _isLP[_lp] = false;
    }

    function createMainPair() external onlyOwner {
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(
            address(this),
            _primarySwapRouter.WETH()
        );
        _isLP[_primaryLP] = true;
    }

    function startTrade() internal {
        _tradingOpen = true;
        startBlock = block.number;
    }

    function enableAutoTrading(bool _able) external onlyOwner {
        // if you want to start trading by adding liquidity
        //  After using Create Main Pair and enable

        //  if you want to start trading by ...
        //  Enable after adding liquidity
        autoTrading = _able;
    }

    function startTradeManual() external onlyOwner {
        require(!_tradingOpen, "Trading Already Opened");
        _tradingOpen = true;
        startBlock = block.number;
    }

    function multiNoFee(address[] calldata noFeeList, bool isNoFee)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < noFeeList.length; i++) {
            _noFees[noFeeList[i]] = isNoFee;
        }
    }

    function multiBcList(address[] calldata bcList, bool isBlack)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < bcList.length; i++) {
            _isBot[bcList[i]] = isBlack;
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        require(!_checkBot(sender), "Bot");

        if (!_inTaxSwap && _isLP[recipient]) {
            _swapTaxAndLiquify();
        }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;
        if (_taxAmount > 0) {
            //  AntiBot
            if (_isLP[sender])
                if (startBlock + 2 > block.number) {
                    _isBot[recipient] = true;
                }

            _balances[address(this)] += _taxAmount;
        }
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkBot(address bot) public view returns (bool) {
        if (_isLP[bot] || bot == address(this) || _noFees[bot]) return false;
        //Vitalik is a bot
        if (bot == address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B))
            return true;
        return _isBot[bot];
    }

    function _checkTradingOpen(address sender, address recipient)
        private
        returns (bool)
    {
        bool checkResult = false;
        if (_tradingOpen) {
            checkResult = true;
        } else {
            //Trading is not opened here
            if (
                (_isLP[sender] && _noFees[recipient] && autoTrading) ||
                (_isLP[recipient] && _noFees[sender] && autoTrading)
            ) {
                startTrade();
                checkResult = true;
            }

            if (_noFees[sender]) {
                checkResult = true;
            }
        }
        return checkResult;
    }

    function tax()
        internal
        view
        returns (uint32 taxNumerator, uint32 taxDenominator)
    {
        (uint32 numerator, uint32 denominator) = (taxValue, 100_000);
        return (numerator, denominator);
    }

    function changeTaxValue(uint32 _taxValue) external onlyOwner {
        require(taxValue <= 30000, "Fee Too High");
        taxValue = _taxValue;
    }

    function _calculateTax(
        address sender,
        address recipient,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 taxAmount;

        if (_tradingOpen && !_noFees[sender] && !_noFees[recipient]) {
            if (_isLP[sender] || _isLP[recipient]) {
                (uint32 numerator, uint32 denominator) = tax();
                taxAmount = (amount * numerator) / denominator;
            }
        }

        return taxAmount;
    }

    function marketingMultisig() external pure returns (address) {
        return _walletMarketing;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if (_taxTokensAvailable >= _taxSwapMin && _tradingOpen) {
            if (_taxTokensAvailable >= _taxSwapMax) {
                _taxTokensAvailable = _taxSwapMax;
            }

            uint256 _tokensToSwap = _taxTokensAvailable;
            if (_tokensToSwap > 10**_decimals) {
                _swapTaxTokensForEth(_tokensToSwap);
            }
            uint256 _contractETHBalance = address(this).balance;
            if (_contractETHBalance > 0) {
                (bool sent, bytes memory data) = _walletMarketing.call{
                    value: _contractETHBalance
                }("");
            }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}