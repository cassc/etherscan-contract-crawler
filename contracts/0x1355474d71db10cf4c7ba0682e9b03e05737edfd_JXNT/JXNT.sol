/**
 *Submitted for verification at Etherscan.io on 2023-09-04
*/

// SPDX-License-Identifier: MIT

/**

Website: https://jxnt.cc
Telegram: https://t.me/jiangxiangnatie
Twitter: https://twitter.com/JiangxiangNatie

**/
pragma solidity 0.8.0;

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

contract JXNT is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;
    address payable private _taxWallet;

    uint256 private _initialBuyTax = 50;
    uint256 private _initialSellTax = 50;
    uint256 private _finalBuyTax = 2;
    uint256 private _finalSellTax = 2;
    uint256 private _reduceBuyTaxAt = 20;
    uint256 private _reduceSellTaxAt = 30;
    uint256 private _buyCount = 0;

    string private constant _name = unicode"酱香拿铁";
    string private constant _symbol = unicode"酱香拿铁";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;
    uint256 public _maxTxAmount = (_tTotal * 1) / 100;
    uint256 public _maxWalletSize = (_tTotal * 1) / 100;
    uint256 public _taxSwapThreshold = (_tTotal * 2) / 1000;
    uint256 public _maxTaxSwap = (_tTotal * 1) / 100;
    uint256 private _teamShare = (_tTotal * 3) / 100;

    mapping(address => bool) public whitelist;
    uint256 private _whitelistMaxAmount = (_tTotal * 1) / 100;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
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
        whitelist[0x18a706e7BB6b509F7d4ab7fc0f6345C2289c045F] = true;
        whitelist[0xf150f8FC468439e47112E4575B57813c89658054] = true;
        whitelist[0x9233d4e2F1eEF619FFc3C07220fd89ab1Ac0CE98] = true;
        whitelist[0x68EC1aB476521EBD04dd7F0dB40D1Bb3f4C00cD7] = true;
        whitelist[0xC1dB67c856c72716f4e9Db08de52691134876980] = true;
        whitelist[0x833857D271EA78C80D437E3229c0Ae6AA80bBeE8] = true;
        whitelist[0x982b22a3e9366176aD9817c3467Fc960DA69f165] = true;
        whitelist[0x337C0ef05495c731aA677E583b6AC87D2083Ce14] = true;
        whitelist[0x8dC485e5e3335e365C53fA7533A6998646cB6Baa] = true;
        whitelist[0x09981aD1f733de8a9549B60A496698eB3eaE0129] = true;
        whitelist[0x2583c5dDF9C70647BD5E8c8893678303EFB6A8BD] = true;
        whitelist[0x1FA27b09B23b23517fFd8Ff7C6C67C4CA3cA921f] = true;
        whitelist[0xC230Fc1bd50aCEfe2b0C815293C3Ed7ff0b90fc2] = true;
        whitelist[0x5B4ED4Ff7E3e6cF918A345b1145Ae2291454a87f] = true;
        whitelist[0x2Dac8a8DfDa482d9D9186232294C70af9A342FE5] = true;
        whitelist[0x43fFa9008317e8fD724bbC668eb8184432B6CCA5] = true;
        whitelist[0xb7226E67e924df91E32BE53a99240207dd703E5C] = true;
        whitelist[0xAc4F7ae3AB7Ac57Dd24b723C5dB61e5e32938997] = true;
        whitelist[0x0F8f7528f7887405baE3f91A38d8244006F77122] = true;
        whitelist[0xfC055b6BAEa363D48d579646aEc4BcCAca58cD83] = true;
        whitelist[0xfbB00a557eD7164b6693978af770E3e8c795030b] = true;
        whitelist[0x7AC0FcDa76dd0e31dedFd8D3AF1378C25acdE38A] = true;

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
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && !whitelist[to]) {
            // Delay transfers
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

            // buy
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

                uint256 tax = (_buyCount > _reduceBuyTaxAt)
                    ? _finalBuyTax
                    : _initialBuyTax;

                taxAmount = (amount * tax) / 100;

                _buyCount++;
            }

            // sell
            if (to == uniswapV2Pair && from != address(this)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                uint256 tax = (_buyCount > _reduceSellTaxAt)
                    ? _finalSellTax
                    : _initialSellTax;
                taxAmount = (amount * tax) / 100;
            }

            // swap tokens for eth
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        } else if (whitelist[to]) {
            require(
                amount <= _whitelistMaxAmount,
                "Exceeds the _whitelistMaxAmount."
            );
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount - taxAmount;
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
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");

        _approve(address(this), address(uniswapV2Router), _tTotal);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)) - _teamShare,
            0,
            0,
            owner(),
            block.timestamp
        );

        swapEnabled = true;
        tradingOpen = true;
    }

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

    receive() external payable {}
}