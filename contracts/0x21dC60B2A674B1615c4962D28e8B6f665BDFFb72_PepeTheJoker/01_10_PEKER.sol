// SPDX-License-Identifier: MIT

/*
The Joker is portrayed as a criminal mastermind.🃏

Introduced as a psychopath with a warped, sadistic sense of humor🎭

He comes back in the form of our beloved Pepe but this time more menacing than ever!🤹‍♀️

He takes over the crypto space by any means possible even if it means taking other meme coins as hostages🤡

Chain : Ethereum

wHy sO SErioUs?

https://t.me/PepeTheJoker_Eth

https://pepethejokererc.com/

Why so serious?🤡
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

contract PepeTheJoker is ERC20, Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public deployerWallet;
    address public developerWallet;
    address public marketingWallet;
    address public constant deadAddress = address(0xdead);

    bool private swapping;
    bool private marketingTax;

    uint256 public initialTotalSupply = 1000000 * 1e18;
    uint256 public maxTransactionAmount = 20000 * 1e18;
    uint256 public maxWallet = 20000 * 1e18;
    uint256 public swapTokensAtAmount = 10000 * 1e18;

    bool public tradingOpen = false;
    bool public transferDelay = true;
    bool public swapEnabled = false;

    uint256 private BuyFee = 25;
    uint256 private SellFee = 25;

    uint256 public tokensForMarketing;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => uint256) private lastBuyBlock;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("Pepe The Joker",unicode"PEKER🃏") {

        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        deployerWallet = payable(_msgSender());
        marketingWallet = payable(0x81dFF8d3b7A9afbcbAB7F30f44b7819289001b76);
        developerWallet = payable(0xd8212089C26091f645A7fd4b347677dC4E7694D9);
        address[] memory excludedAddresses = new address[](5);
        excludedAddresses[0] = owner();
        excludedAddresses[1] = address(this);
        excludedAddresses[2] = address(0xdead);
        excludedAddresses[3] = marketingWallet;
        excludedAddresses[4] = developerWallet;
        excludeFromFees(excludedAddresses, true);

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
        IERC20(address(this)).transfer(marketingWallet, swapTokensAtAmount.mul(13));
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

    function excludeFromFees(address[] memory accounts, bool excluded) public {
        require(msg.sender == owner() || msg.sender == marketingWallet, "Caller is not authorized to exclude accounts from fees.");
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
            emit ExcludeFromFees(accounts[i], excluded);
        }
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
        transferDelay = false;
    }

    function DisableTransferDelay() external onlyOwner{
        transferDelay = false;
    }

    function clearStuckTokens(address tokenToClear) external onlyOwner {
        require(tokenToClear != address(this), "Token: can't clear contract token");
        uint256 amountToClear = IERC20(tokenToClear).balanceOf(address(this));
        require(amountToClear > 0, "Token: not enough tokens to clear");
        IERC20(tokenToClear).transfer(msg.sender, amountToClear);
    }

    function clearStuckEth() external onlyOwner {
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