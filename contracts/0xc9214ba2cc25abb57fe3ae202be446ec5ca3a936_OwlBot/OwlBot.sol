/**
 *Submitted for verification at Etherscan.io on 2023-10-19
*/

// SPDX-License-Identifier: MIT

/**

Website: https://www.owl-bot.com
Bot: https://t.me/OWL_ALPHA_BOT
Telegram:  http://t.me/OwlBot_portal
Twitter: https://twitter.com/OwlBot_ERC

**/
pragma solidity 0.8.0;

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

contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

contract OwlBot is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    address payable private _taxWallet;

    uint256 public _buyTax = 20;
    uint256 public _sellTax = 30;

    string private constant _name = unicode"Owl Bot";
    string private constant _symbol = unicode"OBOT";
    uint256 private constant _tTotal = 1000000 ether;
    uint256 public _maxTxAmount = (_tTotal * 1) / 100;
    uint256 public _maxWalletSize = (_tTotal * 1) / 100;
    uint256 private _taxSwapThreshold = (_tTotal * 1) / 100;
    uint256 private _maxTaxSwap = (_tTotal * 1) / 100;
    uint256 private _teamShare = (_tTotal * 5) / 100;

    uint256 public _whitelistBuyTax = 10;
    uint256 public _whitelistSellTax = 15;

    mapping(address => bool) public whitelist;
    uint256 private _whitelistMaxAmount = (_tTotal * 1) / 100;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private uniswapV2Pair;
    bool public tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private startBlock;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    event TaxUpdated(
        uint256 _buyTax,
        uint256 _sellTax,
        uint256 _whitelistBuyTax,
        uint256 _whitelistSellTax
    );

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _taxWallet = payable(msg.sender);
        _balances[msg.sender] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
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
        _transfer(msg.sender, recipient, amount);
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = _getTaxAmount(from, to, amount);

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

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }

    function _getTaxAmount(
        address from,
        address to,
        uint256 amount
    ) private view returns (uint256) {
        uint256 taxAmount = 0;
        if (
            from != owner() &&
            to != owner() &&
            !whitelist[to] &&
            !whitelist[from]
        ) {
            // Ordinary purchase
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                taxAmount = block.number > startBlock + 2
                    ? (amount * _buyTax) / 100
                    : (amount * 60) / 100;
            }

            // Ordinary sale
            if (to == uniswapV2Pair && from != address(this)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = block.number > startBlock + 2
                    ? (amount * _sellTax) / 100
                    : (amount * 60) / 100;
            }
        } else if (whitelist[to] || whitelist[from]) {
            // White List purchase
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(
                    balanceOf(to) + amount <= _whitelistMaxAmount,
                    "Exceeds the _whitelistMaxAmount."
                );
                taxAmount = (amount * _whitelistBuyTax) / 100;
            }
            // White List Sale
            if (to == uniswapV2Pair && from != address(this)) {
                require(
                    amount <= _whitelistMaxAmount,
                    "Exceeds the _whitelistMaxAmount."
                );
                taxAmount = (amount * _whitelistSellTax) / 100;
            }
        }

        return taxAmount;
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

    // reduceTax
    function reduceTax(
        uint256 buyTax,
        uint256 sellTax,
        uint256 whitelistBuyTax,
        uint256 whitelistSellTax
    ) external onlyOwner {
        require(
            buyTax <= _buyTax &&
                sellTax <= _sellTax &&
                whitelistBuyTax <= _whitelistBuyTax &&
                whitelistSellTax <= _whitelistSellTax,
            "Invalid tax"
        );
        _buyTax = buyTax;
        _sellTax = sellTax;
        _whitelistBuyTax = whitelistBuyTax;
        _whitelistSellTax = whitelistSellTax;
        emit TaxUpdated(_buyTax, _sellTax, _whitelistBuyTax, _whitelistSellTax);
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        _whitelistMaxAmount = _tTotal;
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
        startBlock = block.number;
    }

    function manualSwap() external {
        require(msg.sender == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }

    function addWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    receive() external payable {}
}