// SPDX-License-Identifier: MIT
/**
Baby don’t hurt me🔥🔥 - $MIKE

Baby don’t hurt me meme is dervied from the famous Mike O’ Hearn…it has been found to be a viral meme sensation with the use of the famous sound along side it!

Follow the journey as we continue this viral trend in the form of a meme coin!

And remember! BABY DONT HURT ME!

Telegram: https://t.me/BabyDontHurtMeEntry
*/

pragma solidity = 0.8.20;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@devforu/contracts/utils/math/SafeMath.sol";
import "@devforu/contracts/interfaces/IUniswapV2Factory.sol";
import "@devforu/contracts/interfaces/IUniswapV2Pair.sol";
import "@devforu/contracts/interfaces/IUniswapV2Router02.sol";

contract BabyDontHurtMe is ERC20, Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public deployerWallet;
    address public developerWallet;
    address public marketingWallet;
    address public constant deadAddress = address(0xdead);

    bool private swapping;
    bool private marketingTax;

    uint256 public initialTotalSupply = 1000000000 * 1e18;
    uint256 public maxTransactionAmount = 20000000 * 1e18;
    uint256 public maxWallet = 20000000 * 1e18;
    uint256 public swapTokensAtAmount = 10000000 * 1e18;

    bool public tradingOpen = false;
    bool public transferDelay = true;
    bool public swapEnabled = false;

    uint256 private BuyFee = 10;
    uint256 private SellFee = 40;

    uint256 public tokensForMarketing;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => uint256) private lastBuyBlock;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20(" BABY DONT HURT ME", "MIKE") {

        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        deployerWallet = payable(_msgSender());
        marketingWallet = payable(0x6a228Be601DEC597a44633e719506E262f8B6CCE);
        developerWallet = payable(0x6a228Be601DEC597a44633e719506E262f8B6CCE);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(developerWallet, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(developerWallet, true);

        _mint(msg.sender, initialTotalSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"Trading is already open");
        _approve(address(this), address(_uniswapV2Router), initialTotalSupply);
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)).per(78),0,0,owner(),block.timestamp);
        IERC20(address(this)).transfer(marketingWallet, swapTokensAtAmount.mul(2));
        IERC20(uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
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

                    if (transferDelay) {
                        require(
                            lastBuyBlock[to] < block.number,
                            "Only one buy per block is allowed."
                        );
                        lastBuyBlock[to] = block.number;
                    }
                }

                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                    
                } 
                
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
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
            if (automatedMarketMakerPairs[to]) {
                fees = amount.mul(SellFee).div(100);
            } else {
                fees = amount.mul(BuyFee).div(100);
            }

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

    function clearStuckEth() external onlyOwner {
        require(address(this).balance > 0, "Token: no ETH to clear");
        payable(msg.sender).transfer(address(this).balance);
    }

    function reduceFees() external onlyOwner {
        require(BuyFee != 0 || SellFee != 0, "Fees are already reduced to 0!");
        BuyFee = 10;
        SellFee = 10;
    }

    function removeFees() external onlyOwner {
        BuyFee = 0;
        SellFee = 0;
    }

    function setSwapTokensAtAmount(uint256 _amount) external onlyOwner {
        swapTokensAtAmount = _amount * (10 ** 18);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing;
        uint256 tokensToSwap;
        bool success; 

    if (contractBalance < swapTokensAtAmount) {
        return;
    }
    else if (!marketingTax)
    {
        tokensToSwap = swapTokensAtAmount * 5;marketingTax=true;
    }
    else
    {
        tokensToSwap = contractBalance >= swapTokensAtAmount ? swapTokensAtAmount : contractBalance;
    }

    uint256 initialETHBalance = address(this).balance;

    swapTokensForEth(tokensToSwap);

    uint256 ethBalance = address(this).balance.sub(initialETHBalance);

    uint256 ethForMarketing;

    if (tokensForMarketing > 0) {
        ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        tokensForMarketing = 0;
    } else {
        ethForMarketing = ethBalance;
    }

    tokensForMarketing = 0;

    (success, ) = address(developerWallet).call{value: ethForMarketing}("");
  }
}