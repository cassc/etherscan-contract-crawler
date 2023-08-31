// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


contract StakeForce is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public developmentWallet;
    address public communityFundWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 private buyMarketingFee;
    uint256 private buyDevelopmentFee;
    uint256 private buyCommunityFundFee;

    uint256 public sellTotalFees;
    uint256 private sellMarketingFee;
    uint256 private sellDevelopmentFee;
    uint256 private sellCommunityFundFee;

    uint256 private tokensForMarketing;
    uint256 private tokensForDevelopment;
    uint256 private tokensForCommunityFund;
    uint256 private previousFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event developmentWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event communityFundWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor() ERC20("StakeForce", "FORCE") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        uint256 totalSupply = 100_000_000_000 ether;

        maxTransactionAmount = (totalSupply) / 3000; //0.3% of total supply
        maxWallet = (totalSupply) / 100;  //1% of total supply
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        buyMarketingFee = 5;
        buyDevelopmentFee = 5;
        buyCommunityFundFee = 5;
        buyTotalFees =
            buyMarketingFee +
            buyDevelopmentFee +
            buyCommunityFundFee;

        sellMarketingFee = 10;
        sellDevelopmentFee = 10;
        sellCommunityFundFee = 10;
        sellTotalFees =
            sellMarketingFee +
            sellDevelopmentFee +
            sellCommunityFundFee;

        previousFee = sellTotalFees;

        marketingWallet = address(0x41267f7a282529d89654739cF03128EE73d440e2);
        developmentWallet = address(0x41267f7a282529d89654739cF03128EE73d440e2);
        communityFundWallet = address(0x41267f7a282529d89654739cF03128EE73d440e2);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(developmentWallet, true);
        excludeFromFees(communityFundWallet, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(developmentWallet, true);
        excludeFromMaxTransaction(communityFundWallet, true);

        _mint(address(this), totalSupply);
    }

    receive() external payable {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Trading already active.");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uint256 tokensInWallet = balanceOf(address(this));
        uint256 tokensToAdd = tokensInWallet * 9 / 10; //90% of tokens in wallet go to LP

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokensToAdd,
            0,
            0,
            owner(),
            block.timestamp
        );

        tradingActive = true;
        swapEnabled = true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "ERC20: Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "ERC20: Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxWalletAndTxnAmount(
        uint256 newTxnNum,
        uint256 newMaxWalletNum
    ) external onlyOwner {
        require(
            newTxnNum >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxTxn lower than 0.5%"
        );
        require(
            newMaxWalletNum >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newMaxWalletNum;
        maxTransactionAmount = newTxnNum;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _developmentFee,
        uint256 _communityFundFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyDevelopmentFee = _developmentFee;
        buyCommunityFundFee = _communityFundFee;
        buyTotalFees =
            buyMarketingFee +
            buyDevelopmentFee +
            buyCommunityFundFee;
        require(buyTotalFees <= 10, "ERC20: Must keep fees at 10% or less");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _developmentFee,
        uint256 _communityFundFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellDevelopmentFee = _developmentFee;
        sellCommunityFundFee = _communityFundFee;
        sellTotalFees =
            sellMarketingFee +
            sellDevelopmentFee +
            sellCommunityFundFee;
        previousFee = sellTotalFees;
        require(sellTotalFees <= 10, "ERC20: Must keep fees at 10% or less");
    }

    function updateMarketingWallet(address _marketingWallet)
        external
        onlyOwner
    {
        require(_marketingWallet != address(0), "ERC20: Address 0");
        address oldWallet = marketingWallet;
        marketingWallet = _marketingWallet;
        emit marketingWalletUpdated(marketingWallet, oldWallet);
    }

    function updateDevelopmentWallet(address _developmentWallet)
        external
        onlyOwner
    {
        require(_developmentWallet != address(0), "ERC20: Address 0");
        address oldWallet = developmentWallet;
        developmentWallet = _developmentWallet;
        emit developmentWalletUpdated(developmentWallet, oldWallet);
    }

    function updateCommunityFundWallet(address _communityFundWallet)
        external
        onlyOwner
    {
        require(_communityFundWallet != address(0), "ERC20: Address 0");
        address oldWallet = communityFundWallet;
        communityFundWallet = _communityFundWallet;
        emit communityFundWalletUpdated(communityFundWallet, oldWallet);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint256 amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != deadAddress &&
            !swapping
        ) {
            if (!tradingActive) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "ERC20: Trading is not active."
                );
            }

            //when buy
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
            //when sell
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Sell transfer amount exceeds the maxTransactionAmount."
                );
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
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
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForCommunityFund +=
                    (fees * sellCommunityFundFee) /
                    sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                tokensForDevelopment +=
                    (fees * sellDevelopmentFee) /
                    sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForCommunityFund +=
                    (fees * buyCommunityFundFee) /
                    buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForDevelopment +=
                    (fees * buyDevelopmentFee) /
                    buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
        sellTotalFees = previousFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForCommunityFund +
            tokensForMarketing +
            tokensForDevelopment;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);

        uint256 ethBalance = address(this).balance;

        uint256 ethForDevelopment = ethBalance.mul(tokensForDevelopment).div(
            totalTokensToSwap
        );

        uint256 ethForCommunityFund = ethBalance
            .mul(tokensForCommunityFund)
            .div(totalTokensToSwap);

        tokensForMarketing = 0;
        tokensForDevelopment = 0;
        tokensForCommunityFund = 0;

        (success, ) = address(communityFundWallet).call{
            value: ethForCommunityFund
        }("");

        (success, ) = address(developmentWallet).call{value: ethForDevelopment}(
            ""
        );

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }
}