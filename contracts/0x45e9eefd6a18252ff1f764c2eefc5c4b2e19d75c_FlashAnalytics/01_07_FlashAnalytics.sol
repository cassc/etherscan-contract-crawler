/**
    Flash Analytics
    Empowering Investors and Optimizing Performance through Data Collection and Token Analysis.

    Tax fees = 3/3%
    1% = Holders
    1% = Team
    1% = Liquidity

    Website: https://flash-analytics.com
    Twitter: https://twitter.com/flash_defi
    Telegram: https://t.me/FlashAnalytics
    Discord: https://discord.gg/flashanalytics
    GitBook: https://flash-analytics.gitbook.io/flash-analytics
**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )  external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract FlashAnalytics is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public teamWallet;
    address public holdersWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    bool public blacklistRenounced = false;

    mapping(address => bool) blacklisted;

    uint256 public buyTotalFees;
    uint256 public buyHoldersFee;
    uint256 public buyLiquidityFee;
    uint256 public buyTeamFee;

    uint256 public sellTotalFees;
    uint256 public sellHoldersFee;
    uint256 public sellLiquidityFee;
    uint256 public sellTeamFee;

    uint256 public tokensForHolders;
    uint256 public tokensForLiquidity;
    uint256 public tokensForTeam;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public preMigrationTransferrable;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event holdersWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event teamWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20("FlashAnalytics", "FLASH") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyHoldersFee = 5;
        uint256 _buyLiquidityFee = 5;
        uint256 _buyTeamFee = 10;

        uint256 _sellHoldersFee = 5;
        uint256 _sellLiquidityFee = 5;
        uint256 _sellTeamFee = 10;

        uint256 totalSupply = 1_000_000 * 1e18;

        maxTransactionAmount = 10_000 * 1e18; // 1%
        maxWallet = 20_000 * 1e18; // 2%
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05%

        buyHoldersFee = _buyHoldersFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTeamFee = _buyTeamFee;
        buyTotalFees = buyHoldersFee + buyLiquidityFee + buyTeamFee;

        sellHoldersFee = _sellHoldersFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTeamFee = _sellTeamFee;
        sellTotalFees = sellHoldersFee + sellLiquidityFee + sellTeamFee;

        holdersWallet = address(0xb4B606DFc51AC35096D3472F6cC3B5f9C439aD61);
        teamWallet = address(0x8D8Ce6b892C83edd2BF695eB221FE658673923F6);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "trading is already active");

        addLiquidity(balanceOf(address(this)), address(this).balance);

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        
        tradingActive = true;
        swapEnabled = true;
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;

        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
        require(newAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% total supply.");

        swapTokensAtAmount = newAmount;

        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 5) / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.5%");

        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 10) / 1000) / 1e18, "Cannot set maxWallet lower than 1.0%");

        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _holdersFee,
        uint256 _liquidityFee,
        uint256 _teamFee
    ) external onlyOwner {
        buyHoldersFee = _holdersFee;
        buyLiquidityFee = _liquidityFee;
        buyTeamFee = _teamFee;
        buyTotalFees = buyHoldersFee + buyLiquidityFee + buyTeamFee;
        require(buyTotalFees <= 5, "Buy fees must be <= 5.");
    }

    function updateSellFees(
        uint256 _holdersFee,
        uint256 _liquidityFee,
        uint256 _teamFee
    ) external onlyOwner {
        sellHoldersFee = _holdersFee;
        sellLiquidityFee = _liquidityFee;
        sellTeamFee = _teamFee;
        sellTotalFees = sellHoldersFee + sellLiquidityFee + sellTeamFee;
        require(sellTotalFees <= 5, "Sell fees must be <= 5.");
    }

    function updateBuyAndSellFees(
        uint256 _holdersFee,
        uint256 _liquidityFee,
        uint256 _teamFee
    ) external onlyOwner {
        buyHoldersFee = _holdersFee;
        buyLiquidityFee = _liquidityFee;
        buyTeamFee = _teamFee;
        sellHoldersFee = _holdersFee;
        sellLiquidityFee = _liquidityFee;
        sellTeamFee = _teamFee;
        sellTotalFees = sellHoldersFee + sellLiquidityFee + sellTeamFee;
        buyTotalFees = buyHoldersFee + buyLiquidityFee + buyTeamFee;
        require(buyTotalFees <= 5 && sellTotalFees <= 5, "Buy and sell fees must be <= 5.");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateHoldersWallet(address newWallet) external onlyOwner {
        holdersWallet = newWallet;
        emit holdersWalletUpdated(newWallet, holdersWallet);
    }

    function updateTeamWallet(address newWallet) external onlyOwner {
        teamWallet = newWallet;
        emit teamWalletUpdated(newWallet, teamWallet);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from], "Sender blacklisted");
        require(!blacklisted[to], "Receiver blacklisted");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForTeam += (fees * sellTeamFee) / sellTotalFees;
                tokensForHolders += (fees * sellHoldersFee) / sellTotalFees;
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForTeam += (fees * buyTeamFee) / buyTotalFees;
                tokensForHolders += (fees * buyHoldersFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForHolders + tokensForTeam;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens).sub(tokensForHolders);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForLiquidity = ethBalance.mul(20).div(100); // 20%

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        tokensForLiquidity = 0;
        tokensForHolders = 0;
        tokensForTeam = 0;

        super._transfer(address(this), holdersWallet, balanceOf(address(this)));

        (success, ) = address(teamWallet).call{value: address(this).balance}("");
    }

    function withdrawStuckToken(address _token, address _to) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");

        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{value: address(this).balance}("");

        require(success);
    }

    function renounceBlacklist() public onlyOwner {
        blacklistRenounced = true;
    }

    function blacklist(address _addr) public onlyOwner {
        require(!blacklistRenounced, "Team has revoked blacklist rights");
        require(_addr != address(uniswapV2Pair) && _addr != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), "Cannot blacklist token's v2 router or v2 pool.");

        blacklisted[_addr] = true;
    }

    function blacklistLiquidityPool(address lpAddress) public onlyOwner {
        require(!blacklistRenounced, "Team has revoked blacklist rights");
        require(lpAddress != address(uniswapV2Pair) && lpAddress != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), "Cannot blacklist token's v2 router or v2 pool.");

        blacklisted[lpAddress] = true;
    }

    function unblacklist(address _addr) public onlyOwner {
        blacklisted[_addr] = false;
    }
}