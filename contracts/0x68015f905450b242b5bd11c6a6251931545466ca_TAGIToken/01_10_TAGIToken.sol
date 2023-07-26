/*
    Twitter:    https://twitter.com/TagAI_Tech
    TG:         https://t.me/tagai_techERC
    Website:    https://tag-ai.tech/
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TAGIToken is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) private _isExcludedFromFees;

    uint256 public feesOnBuy;
    uint256 public feesOnSell;

    uint256 private liquidityProvider;

    address public tagAIWallet;
    address private _liquidityProviderWallet;

    uint256 public swapTokensAtAmount;
    bool private swapping;

    bool public swapEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event TagAIWalletChanged(address tagAIWallet);
    event LiquiditydWalletChanged(address _liquidityProviderWallet);
    event UpdateFees(uint256 feesOnBuy, uint256 feesOnSell);
    event SwapAndSendTagAI(uint256 tokensSwapped, uint256 bnbSend);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);

    error LiquidityProviderUnauthorizedAccount(address account);

    modifier onlyLiquidityProvider() {
        _checkLiquidityProvider();
        _;
    }

    constructor() ERC20("TAG-AI Technology", "TAGI") {
        if (block.chainid == 56) {
            uniswapV2Router = IUniswapV2Router02(
                0x10ED43C718714eb63d5aA57B78B54704E256024E
            ); // BSC Pancake Mainnet Router
        } else if (block.chainid == 97) {
            uniswapV2Router = IUniswapV2Router02(
                0xD99D1c33F9fC3444f8101754aBC46c52416550D1
            ); // BSC Pancake Testnet Router
        } else if (block.chainid == 1 || block.chainid == 5) {
            uniswapV2Router = IUniswapV2Router02(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            ); // ETH Uniswap Mainnet % Testnet
        } else {
            revert();
        }

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        feesOnBuy = 5;
        feesOnSell = 5;

        tagAIWallet = 0xfc361808CB49577742Ad927d76c795c210ED8359;
        _liquidityProviderWallet = 0x443634DcD7543AB0Bf11Bd3f0ee8aaBF79e8549A; //redemitdaoinvestments.eth

        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[address(0xdead)] = true;
        _isExcludedFromMaxWalletLimit[tagAIWallet] = true;
        _isExcludedFromMaxWalletLimit[_liquidityProviderWallet] = true;
        _isExcludedFromMaxWalletLimit[
            0xE77dF2aB21c1CCDea839f40BD7Aab674ebA9Ae80
        ] = true;
        _isExcludedFromMaxWalletLimit[
            0x97BC47f8169c3a49B46CB4EBe634AbEdB291E047
        ] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_liquidityProviderWallet] = true;
        _isExcludedFromFees[0xE77dF2aB21c1CCDea839f40BD7Aab674ebA9Ae80] = true;
        _isExcludedFromFees[0x97BC47f8169c3a49B46CB4EBe634AbEdB291E047] = true;

        _mint(owner(), 1e6 * (10**decimals()));
        swapTokensAtAmount = totalSupply() / 5_000;

        maxWalletAmount = (totalSupply() * 20) / 1000;

        tradingEnabled = false;
        swapEnabled = false;
    }

    receive() external payable {}

    function claimStuckTokens(address token) external onlyOwner {
        if (token == address(0x0)) {
            payable(msg.sender).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function _checkLiquidityProvider() internal view virtual {
        if (liquidityProviderWallet() != _msgSender()) {
            revert LiquidityProviderUnauthorizedAccount(_msgSender());
        }
    }

    function liquidityProviderWallet() public view virtual returns (address) {
        return _liquidityProviderWallet;
    }

    function excludeFromFees(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function updateFees(uint256 _feesOnSell, uint256 _feesOnBuy)
        external
        onlyOwner
    {
        require(_feesOnSell <= feesOnSell, "You can only decrease the fees");
        require(_feesOnBuy <= feesOnBuy, "You can only decrease the fees");

        feesOnSell = _feesOnSell;
        feesOnBuy = _feesOnBuy;

        emit UpdateFees(feesOnSell, feesOnBuy);
    }

    function changeTagAIWallet(address _tagAIWallet) external onlyOwner {
        require(
            _tagAIWallet != tagAIWallet,
            "TagAI wallet is already that address"
        );
        require(
            _tagAIWallet != address(0),
            "TagAI wallet cannot be the zero address"
        );
        tagAIWallet = _tagAIWallet;

        emit TagAIWalletChanged(tagAIWallet);
    }

    function changeLiquidityWallet(address liquidityProviderWallet_)
        external
        onlyLiquidityProvider
    {
        require(
            liquidityProviderWallet_ != _liquidityProviderWallet,
            "TagAI wallet is already that address"
        );
        require(
            liquidityProviderWallet_ != address(0),
            "TagAI wallet cannot be the zero address"
        );
        _liquidityProviderWallet = liquidityProviderWallet_;

        emit LiquiditydWalletChanged(_liquidityProviderWallet);
    }

    bool public tradingEnabled;
    uint256 public tradingBlock;
    uint256 public tradingTime;

    function enableTrading() external onlyLiquidityProvider {
        require(!tradingEnabled, "Trading already enabled.");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            liquidityProviderWallet(),
            block.timestamp
        );

        maxWalletLimitEnabled = true;
        tradingEnabled = true;
        swapEnabled = true;
        tradingBlock = block.number;
        tradingTime = block.timestamp;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            tradingEnabled ||
                _isExcludedFromFees[from] ||
                _isExcludedFromFees[to],
            "Trading not yet enabled!"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && !swapping && to == uniswapV2Pair && swapEnabled) {
            swapping = true;

            swapAndSendTagAI(contractTokenBalance);

            swapping = false;
        }

        uint256 feeOnBuy;
        uint256 feeOnSell;

        if (block.timestamp > tradingTime + (60 minutes)) {
            // Stage normal
            feeOnBuy = feesOnBuy;
            feeOnSell = feesOnSell;
        } else if (block.timestamp > tradingTime + (50 minutes)) {
            // Stage 5
            feeOnBuy = 10;
            feeOnSell = 15;
        } else if (block.timestamp > tradingTime + (40 minutes)) {
            // Stage 4
            feeOnBuy = 15;
            feeOnSell = 25;
        } else if (block.timestamp > tradingTime + (30 minutes)) {
            // Stage 3
            feeOnBuy = 20;
            feeOnSell = 30;
        } else if (block.timestamp > tradingTime + (20 minutes)) {
            // Stage 2
            feeOnBuy = 30;
            feeOnSell = 35;
        } else {
            // Stage 1
            feeOnBuy = 35;
            feeOnSell = 39;
        }

        uint256 _totalFees;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _totalFees = 0;
        } else if (from == uniswapV2Pair) {
            if (block.number <= tradingBlock) {
                _totalFees = 99;
            } else {
                _totalFees = feeOnBuy;
            }
        } else if (to == uniswapV2Pair) {
            _totalFees = feeOnSell;
        } else {
            _totalFees = 0;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 100;
            amount = amount - fees;
            super._transfer(from, address(this), fees);

            liquidityProvider += fees / 5;
        }

        if (maxWalletLimitEnabled) {
            if (
                !_isExcludedFromMaxWalletLimit[from] &&
                !_isExcludedFromMaxWalletLimit[to] &&
                to != uniswapV2Pair
            ) {
                uint256 balance = balanceOf(to);
                require(
                    balance + amount <= maxWalletAmount,
                    "MaxWallet: Recipient exceeds the maxWalletAmount"
                );
            }
        }

        super._transfer(from, to, amount);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= totalSupply() / 1_000_000,
            "SwapTokensAtAmount must be greater than 0.0001% of total supply"
        );
        require(
            newAmount <= totalSupply() / 1_000,
            "SwapTokensAtAmount must be greater than 0.1% of total supply"
        );
        swapTokensAtAmount = newAmount;

        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }

    function swapAndSendTagAI(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance - initialBalance;
        uint256 liquidityProviderAmount = (newBalance * liquidityProvider) /
            tokenAmount;

        payable(_liquidityProviderWallet).sendValue(liquidityProviderAmount);
        payable(tagAIWallet).sendValue(address(this).balance);

        liquidityProvider = 0;

        emit SwapAndSendTagAI(tokenAmount, newBalance);
    }

    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    bool public maxWalletLimitEnabled;
    uint256 public maxWalletAmount;

    event ExcludedFromMaxWalletLimit(address indexed account, bool isExcluded);
    event MaxWalletLimitStateChanged(bool maxWalletLimit);
    event MaxWalletLimitAmountChanged(uint256 maxWalletAmount);

    function setEnableMaxWalletLimit(bool enable) external onlyOwner {
        require(
            enable != maxWalletLimitEnabled,
            "Max wallet limit is already set to that state"
        );
        maxWalletLimitEnabled = enable;

        emit MaxWalletLimitStateChanged(maxWalletLimitEnabled);
    }

    function excludeFromMaxWallet(address account, bool exclude)
        external
        onlyOwner
    {
        require(
            _isExcludedFromMaxWalletLimit[account] != exclude,
            "Account is already set to that state"
        );
        require(account != address(this), "Can't set this address.");

        _isExcludedFromMaxWalletLimit[account] = exclude;

        emit ExcludedFromMaxWalletLimit(account, exclude);
    }

    function isExcludedFromMaxWalletLimit(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxWalletLimit[account];
    }
}