/**
 *Submitted for verification at Etherscan.io on 2023-08-14
*/

/**

telegram: https://t.me/+mTEqzlYEs-kzYzM8

twitter: https://t.me/+mTEqzlYEs-kzYzM8

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract spurdo is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;
    address payable private _taxWallet;

    uint256 private _initialBuyTax = 10;
    uint256 private _initialSellTax = 30;
    uint256 private _finalBuyTax = 1;
    uint256 private _finalSellTax = 1;
    uint256 public _reduceBuyTaxAt = 30;
    uint256 public _reduceSellTaxAt = 45;
    uint256 private _preventSwapBefore = 30;
    uint256 private _buyCount = 0;

    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 69_000_000_000_000 * 10 ** _decimals;
    string private constant _name = unicode"spurdo";
    string private constant _symbol = unicode"spurdo";
    uint256 public _maxTxAmount = _tTotal / 50;
    uint256 public _maxWalletSize = _tTotal / 50;
    uint256 public _taxSwapThreshold = _tTotal / 1000;
    uint256 public _maxTaxSwap = _tTotal / 1000;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
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
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            if (transferDelayEnabled) {
                if (
                    to != address(uniswapV2Router) &&
                    to != address(uniswapV2Pair)
                ) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "Only one transfer per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                _buyCount++;
            }

            taxAmount =
                (amount *
                    (
                        (_buyCount > _reduceBuyTaxAt)
                            ? _finalBuyTax
                            : _initialBuyTax
                    )) /
                100;
            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount =
                    (amount *
                        (
                            (_buyCount > _reduceSellTaxAt)
                                ? _finalSellTax
                                : _initialSellTax
                        )) /
                    100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + (amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
        if (!tradingOpen) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        _reduceSellTaxAt = 20;
        _reduceBuyTaxAt = 20;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function changeSwapAmount(uint256 amount) external onlyOwner {
        _maxTaxSwap = amount * 1e8;
        _taxSwapThreshold = _maxTaxSwap;
    }

    function Launch() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }
}