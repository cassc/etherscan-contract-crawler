/**
 *Submitted for verification at Etherscan.io on 2023-07-11
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

    function getPair(address tokenA, address tokenB)
        external
        view
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
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

contract ETH2 is IERC20, Auth {
    using SafeMath for uint256;
    string private constant _name = "ETH2.0";
    string private constant _symbol = "ETH2.0";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 120_000_000 * (10**_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint32 private buyTaxValue = 1000;
    uint32 private sellTaxValue = 1000;

    uint256 public maxWalletAmount;

    address payable private constant _walletMarketing =
        payable(0x098f5e601c2bE709925B2a23c6D8DB9D11790340);
    uint256 private constant _taxSwapMin = _totalSupply / 1000;
    uint256 private constant _taxSwapMax = _totalSupply / 200;

    mapping(address => bool) private _noFees;

    uint256 private startBlock;
    mapping(address => bool) private _isBot;

    address private constant _swapRouterAddress =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IUniswapV2Router02 private _primarySwapRouter =
        IUniswapV2Router02(_swapRouterAddress);

    address public _primaryLP;
    mapping(address => bool) public _isLP;

    bool public autoTrading = false;
    bool public _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap() {
        _inTaxSwap = true;
        _;
        _inTaxSwap = false;
    }

    constructor() Auth(msg.sender) {
        address receiver = address(msg.sender);
        _balances[receiver] = _totalSupply;
        maxWalletAmount = (_totalSupply * 11) / 1000;
        emit Transfer(address(0), receiver, _balances[receiver]);

        _noFees[receiver] = true;
        _noFees[address(this)] = true;
        _noFees[_swapRouterAddress] = true;
        _noFees[_walletMarketing] = true;

        address tempLP = IUniswapV2Factory(_primarySwapRouter.factory())
            .createPair(address(this), _primarySwapRouter.WETH());
        _primaryLP = tempLP;
        _isLP[tempLP] = true;
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

    function addPair(address _lp) external onlyOwner {
        _isLP[_lp] = true;
    }

    function removePair(address _lp) external onlyOwner {
        _isLP[_lp] = false;
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

    function setMaxWallet(uint256 _max) external onlyOwner {
        maxWalletAmount = _max;
    }

    function checkAmount(
        address from,
        address to,
        uint256 amount
    ) internal view returns (bool) {
        if (_noFees[from] || _noFees[to]) return true;

        if (_isLP[to]) {
            if (amount > maxWalletAmount) return false;
            return true;
        } else {
            if (amount + balanceOf(to) > maxWalletAmount) return false;
            return true;
        }
    }

    bool swapAndLiquifyEnable = true;

    function setSwapAndLiquifyEnable(bool _able) external onlyOwner {
        swapAndLiquifyEnable = _able;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        require(!_checkBot(sender), "Bot");
        require(checkAmount(sender, recipient, amount), "Amount Exceeds Max");

        if (!_inTaxSwap && _isLP[recipient] && swapAndLiquifyEnable) {
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
            emit Transfer(sender, address(this), _taxAmount);
        }
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, _transferAmount);
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
        returns (
            uint32 buytaxNumerator,
            uint32 selltaxNumerator,
            uint32 taxDenominator
        )
    {
        (uint32 buynumerator, uint32 sellnumerator, uint32 denominator) = (
            buyTaxValue,
            sellTaxValue,
            100_000
        );
        return (buynumerator, sellnumerator, denominator);
    }

    function changeTaxValue(uint32 _buyTaxValue, uint32 _sellTaxValue)
        external
        onlyOwner
    {
        require(_buyTaxValue <= 30000, "Fee Too High");
        require(_sellTaxValue <= 30000, "Fee Too High");
        buyTaxValue = _buyTaxValue;
        sellTaxValue = _sellTaxValue;
    }

    function _calculateTax(
        address sender,
        address recipient,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 taxAmount;

        if (_tradingOpen && !_noFees[sender] && !_noFees[recipient]) {
            (
                uint32 buynumerator,
                uint32 sellnumerator,
                uint32 denominator
            ) = tax();
            if (_isLP[sender])
                taxAmount = (amount * buynumerator) / denominator;
            if (_isLP[recipient])
                taxAmount = (amount * sellnumerator) / denominator;
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

    function emergencyWithdraw(address _token, address to) external onlyOwner {
        IERC20 tempToken = IERC20(_token);
        uint256 tempBal = tempToken.balanceOf(address(this));
        tempToken.transfer(to, tempBal);
    }
}