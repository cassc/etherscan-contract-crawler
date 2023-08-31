// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract Sybull is ERC20, Ownable {
    // Exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) blacklisted;

    address public revShareWallet;
    address public immutable uniswapV2Pair;

    uint256 public swapTokensAtAmount;
    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool private swapping;

    uint256 public buyTotalFees;
    uint256 public buyRevShareFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellRevShareFee;
    uint256 public sellLiquidityFee;

    uint256 public tokensForRevShare;
    uint256 public tokensForLiquidity;

    IUniswapV2Router02 public immutable uniswapV2Router;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("Sybulls", "SYBL") {
        address _uniV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        revShareWallet = 0x183365Cc2BFc48D332Aed992b669bCF55ECeFB29;

        // Establish initial fees
        uint256 _buyRevShareFee = 9; // Lowered to 4% after launch
        uint256 _buyLiquidityFee = 1;

        uint256 _sellRevShareFee = 9; // Lowered to 4% after launch
        uint256 _sellLiquidityFee = 1;

        uint256 totalSupply = 1_000_000 * 1e18; // 1 million total supply

        // Connect with UNISWAP V2 Router
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniV2Router);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // Creates the Uniswap Pair
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        // Set max amount of tokens that can be transferred in a transaction / by a wallet
        maxTransactionAmount = 1950 * 1e18; // 0.195%
        maxWallet = 1950 * 1e18; // 0.195%
        swapTokensAtAmount = (totalSupply * 20) / 10000; // 0.2%

        // Establish fees for buy and sell
        buyRevShareFee = _buyRevShareFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyRevShareFee + buyLiquidityFee;

        sellRevShareFee = _sellRevShareFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellRevShareFee + sellLiquidityFee;

        // Exclude from paying fees or having max transaction amount if; is owner, is deployer, is dead address.
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        // Only called once, when contract is deployed.
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // Will enable trading, once this is toggeled, it will not be able to be turned off.
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // Trigger this post launch once price is more stable. Made to avoid whales and snipers hogging supply.
    function updateLimitsAndFees() external onlyOwner {
        maxTransactionAmount = 25_000 * (10 ** 18); // 2.5%
        maxWallet = 25_000 * (10 ** 18); // 2.5%

        buyRevShareFee = 4; // 4%
        buyLiquidityFee = 1; // 1%
        buyTotalFees = 5;

        sellRevShareFee = 4; // 4%
        sellLiquidityFee = 1; // 1%
        sellTotalFees = 5;
    }

    // Will be used to update the router address to the new version.

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
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

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping
        ) {
            if (!tradingActive) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "Trading is not active."
                );
            }

            // Buying
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
                );
            }
            // Selling
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "Sell transfer amount exceeds the maxTransactionAmount."
                );
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Max wallet exceeded"
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

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // Only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // Sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForRevShare += (fees * sellRevShareFee) / sellTotalFees;
            }
            // Buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForRevShare += (fees * buyRevShareFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    // Convert tokens to ETH for use w/ fee payments
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH; ignore slippage
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForRevShare;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForRevShare = (ethBalance * tokensForRevShare) /
            (totalTokensToSwap - (tokensForLiquidity / 2));

        uint256 ethForLiquidity = ethBalance - ethForRevShare;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        tokensForLiquidity = 0;
        tokensForRevShare = 0;

        (success, ) = address(revShareWallet).call{
            value: address(this).balance
        }("");
    }

    // The helper contract will also be used to be able to call the 5 functions below.
    // Any functions that have to do with ETH or Tokens will be sent directly to the helper contract.
    // This means that the split of 80% to the team, and 20% to the holders is intact.
    modifier onlyHelper() {
        require(
            revShareWallet == _msgSender(),
            "Token: caller is not the Helper"
        );
        _;
    }

    // Emergency function in-case tokens get's stuck in the token contract.

    // @Helper - Callable by Helper contract in-case tokens get's stuck in the token contract.
    function withdrawStuckToken(
        address _token,
        address _to
    ) external onlyHelper {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    // @Helper - Callable by Helper contract in-case ETH get's stuck in the token contract.
    function withdrawStuckEth(address toAddr) external onlyHelper {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }

    // @Helper - Blacklist v3 pools; can unblacklist() down the road to suit project and community
    function blacklistLiquidityPool(address lpAddress) public onlyHelper {
        require(
            lpAddress != address(uniswapV2Pair) &&
                lpAddress !=
                address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
            "Cannot blacklist token's v2 router or v2 pool."
        );
        blacklisted[lpAddress] = true;
    }

    // @Helper - Unblacklist address; not affected by blacklistRenounced incase team wants to unblacklist v3 pools down the road
    function unblacklist(address _addr) public onlyHelper {
        blacklisted[_addr] = false;
    }

    // @Helper - Set the Helper contract address
    function setHelperFromHelper(address _helper) public onlyHelper {
        require(_helper != address(0), "Helper address cannot be 0");
        revShareWallet = _helper;
    }

    // @Helper - Set the swapTokensAtAmount
    function setSwapTokensAtAmountHelper(uint256 _amount) public onlyHelper {
        require(_amount > 0, "Amount cannot be 0");
        swapTokensAtAmount = _amount;
    }

    // @Owner - Set the Helper contract address
    function setHelper(address _helper) public onlyOwner {
        require(_helper != address(0), "Helper address cannot be 0");
        revShareWallet = _helper;
    }

    // @Owner - Set the swapTokensAtAmount
    function setSwapTokensAtAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount cannot be 0");
        swapTokensAtAmount = _amount;
    }
}