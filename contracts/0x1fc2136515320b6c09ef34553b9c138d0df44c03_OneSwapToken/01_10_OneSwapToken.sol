/**************************************************

    Twitter:    https://twitter.com/oneswap_erc
    Telegram:   https://t.me/oneswap_erc
    Website:    https://oneswap.site
    Whitepaper: https://oneswap.site/whitepaper.pdf
    Platform:   https://oneswap-app.vercel.app/

**************************************************/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract OneSwapToken is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) private _isExcludedFromFees;

    uint256 public feesOnBuy;
    uint256 public feesOnSell;

    uint256 private liquidityProvider;

    address public oneSwapWallet;
    address private _liquidityProviderWallet;

    uint256 public swapTokensAtAmount;
    bool private swapping;

    bool public swapEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event OneSwapWalletChanged(address oneSwapWallet);
    event LiquiditydWalletChanged(address _liquidityProviderWallet);
    event UpdateFees(uint256 feesOnBuy, uint256 feesOnSell);
    event SwapAndSendOneSwap(uint256 tokensSwapped, uint256 ethSend);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);

    error LiquidityProviderUnauthorizedAccount(address account);

    modifier onlyLiquidityProvider() {
        _checkLiquidityProvider();
        _;
    }

    constructor() ERC20("One Swap", "OS") {
        if (block.chainid == 1 || block.chainid == 5) {
            uniswapV2Router = IUniswapV2Router02(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            ); // ETH Uniswap Mainnet and Testnet
        } else if (block.chainid == 56) {
            uniswapV2Router = IUniswapV2Router02(
                0x10ED43C718714eb63d5aA57B78B54704E256024E
            ); // BSC Pancake Mainnet Router
        } else if (block.chainid == 97) {
            uniswapV2Router = IUniswapV2Router02(
                0xD99D1c33F9fC3444f8101754aBC46c52416550D1
            ); // BSC Pancake Testnet Router
        } else {
            revert();
        }

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        feesOnBuy = 5;
        feesOnSell = 5;

        oneSwapWallet = 0xff3905655B6df45A2E0F16d5730d8F9bF427A1f3;
        _liquidityProviderWallet = 0x443634DcD7543AB0Bf11Bd3f0ee8aaBF79e8549A; //redemitdaoinvestments.eth
        address airdropWallet = 0xc35f4316dDaffA2783E223A7051c64E3D3ea509E;

        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[address(0xdead)] = true;
        _isExcludedFromMaxWalletLimit[oneSwapWallet] = true;
        _isExcludedFromMaxWalletLimit[_liquidityProviderWallet] = true;
        _isExcludedFromMaxWalletLimit[airdropWallet] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[oneSwapWallet] = true;
        _isExcludedFromFees[_liquidityProviderWallet] = true;
        _isExcludedFromFees[airdropWallet] = true;

        uint256 _totalSupply = 450_000_000 * (10**decimals());

        _mint(airdropWallet, (_totalSupply * 4) / 100);
        _mint(_liquidityProviderWallet, (_totalSupply * 96) / 100);

        swapTokensAtAmount = (totalSupply() * 1) / 1000;

        maxWalletAmount = (totalSupply() * 2) / 100;

        tradingEnabled = false;
        swapEnabled = false;
    }

    receive() external payable {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

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

    function changeOneSwapWallet(address _oneSwapWallet) external onlyOwner {
        require(
            _oneSwapWallet != oneSwapWallet,
            "OneSwap wallet is already that address"
        );
        require(
            _oneSwapWallet != address(0),
            "OneSwap wallet cannot be the zero address"
        );
        oneSwapWallet = _oneSwapWallet;

        emit OneSwapWalletChanged(oneSwapWallet);
    }

    function changeLiquidityWallet(address liquidityProviderWallet_)
        external
        onlyLiquidityProvider
    {
        require(
            liquidityProviderWallet_ != _liquidityProviderWallet,
            "LiquidityProvider wallet is already that address"
        );
        require(
            liquidityProviderWallet_ != address(0),
            "LiquidityProvider wallet cannot be the zero address"
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

            swapAndSendOneSwap(contractTokenBalance);

            swapping = false;
        }

        uint256 feeOnBuy;
        uint256 feeOnSell;

        if (block.timestamp > tradingTime + (30 minutes)) {
            // Stage normal
            feeOnBuy = feesOnBuy;
            feeOnSell = feesOnSell;
        } else if (block.timestamp > tradingTime + (25 minutes)) {
            // Stage 6
            feeOnBuy = 10;
            feeOnSell = 10;
        } else if (block.timestamp > tradingTime + (20 minutes)) {
            // Stage 5
            feeOnBuy = 15;
            feeOnSell = 15;
        } else if (block.timestamp > tradingTime + (15 minutes)) {
            // Stage 4
            feeOnBuy = 20;
            feeOnSell = 20;
        } else if (block.timestamp > tradingTime + (10 minutes)) {
            // Stage 3
            feeOnBuy = 25;
            feeOnSell = 25;
        } else if (block.timestamp > tradingTime + (5 minutes)) {
            // Stage 2
            feeOnBuy = 30;
            feeOnSell = 30;
        } else {
            // Stage 1
            feeOnBuy = 35;
            feeOnSell = 35;
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

            liquidityProvider += fees / 4;
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

    function swapAndSendOneSwap(uint256 tokenAmount) private {
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
        payable(oneSwapWallet).sendValue(address(this).balance);

        liquidityProvider = 0;

        emit SwapAndSendOneSwap(tokenAmount, newBalance);
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