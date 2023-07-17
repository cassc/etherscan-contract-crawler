// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
Sorry, we don't have a square to spare.

https://www.papernapkin.vip/

https://twitter.com/PaperNapkinCoin

https://t.me/PaperNapkinCoin

*/

pragma solidity =0.8.15;


contract PaperNapkinCoin is ERC20, Ownable {

    IRouter public thatthingthatswapstokens;
    address public pair;

    address public devWallet;

    uint256 public swapTokensAtAmount;
    uint256 public HowManyNapkinsIBuy;
    uint256 public HowManyNapkinsISell;
    uint256 public maxNapkins;

    mapping(address => bool) private _isExcludedFromPayingMe;
    mapping(address => bool) private _isExcludedFromMaxNapkins;
    mapping(address => bool) public automatedMarketMakerPairs;

    bool private swapping;
    bool public swapEnabled = true;
    bool public tradingEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);


    struct Taxes {
        uint256 dev;
    }

    Taxes public buyTaxes = Taxes(50); // 5% on buy turning to 0% after launch
    Taxes public sellTaxes = Taxes(50); // 5% on sell turning to 0% after launch
    uint256 public totalBuyTax = 50; // 5%
    uint256 public totalSellTax = 50; // 5%

    constructor(address _dev) ERC20("Paper Napkin Coin", "NAPKIN") {

        setSwapTokensAtAmount(500000); //
        updateMaxAmountOfNapkinsICanHave(2000000);
        setMaxAmountOfMaxNapkins(2000000, 2000000);
        setDevWallet(_dev);

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        thatthingthatswapstokens = _router;
        pair = _pair;

        excludeFromPayingMeMoney(owner(), true);
        excludeFromPayingMeMoney(address(this), true);
        excludeFromMaxAmountOfNapkins(_pair, true);
        excludeFromMaxAmountOfNapkins(address(this), true);
        excludeFromMaxAmountOfNapkins(address(_router), true);
        _setAutomatedMarketMakerPair(_pair, true);


        _mint(owner(), 100000000 * (10**18));
    }

    receive() external payable {}



    function setDevWallet(address newWallet) public onlyOwner {
        devWallet = newWallet;
    }

    function CallMeForUtility() public pure returns(string memory){
        return "Send me all your eth and i will tell you secrets";
    }

    function CallMeForFreeETH() public pure returns(string memory){
        return "I lied lol, not a square to spare";
    }
    function WhatYouThinkOfBenEth() public pure returns(string memory){
        return "Write this on a napkin: FUCK THAT DUDE ";
    }


    function excludeFromPayingMeMoney(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromPayingMe[account] != excluded,
            " Account is already the value of 'excluded'"
        );
        _isExcludedFromPayingMe[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleFromOurWraith(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromPayingMe[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }


    function excludeFromMaxAmountOfNapkins(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxNapkins[account] = excluded;
    }

    function updateMaxAmountOfNapkinsICanHave(uint256 newNum) public onlyOwner {
        require(newNum > (1000000 * 1), "Cannot set maxWallet lower than 1%");
        maxNapkins = newNum * (10**18);
    }

    function setMaxAmountOfMaxNapkins(uint256 maxBuy, uint256 maxSell)
        public
        onlyOwner
    {
        require(maxBuy >= 1000000, "Cannot set maxbuy lower than 1% ");
        require(maxSell >= 500000, "Cannot set maxsell lower than 0.5% ");
        HowManyNapkinsIBuy = maxBuy * 10**18;
        HowManyNapkinsISell = maxSell * 10**18;
    }
    function isExcludedFromPayingMe(address account) public view returns (bool) {
        return _isExcludedFromPayingMe[account];
    }


    function setPayMeOnBuy(
        uint256 _dev
    ) external onlyOwner {
        require(_dev <= 250, "Fee must be <= 25%");
        buyTaxes = Taxes( _dev);
        totalBuyTax = _dev;
    }

    function setpayMeOnSell(
        uint256 _dev
    ) external onlyOwner {
        require(_dev <= 250, "Fee must be <= 25%");
        sellTaxes = Taxes( _dev);
        totalSellTax = _dev;
    }

    /// @notice Update the threshold to swap tokens
    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        require(
            amount < 10000000,
            "Cannot set swap-tokens higher then than 10% "
        );
        swapTokensAtAmount = amount * 10**18;
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for trreasury
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }


    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    /// @notice Send remaining ETH to treasuryWallet
    /// @dev It will send all ETH to treasuryWallet
    function forceSend() external onlyOwner {
        (bool success, ) = payable(devWallet).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send Eth");
    }

    function updateRouter(address newRouter) external onlyOwner {
        thatthingthatswapstokens = IRouter(newRouter);
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled);
        tradingEnabled = true;
    }

  

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(address newPair, bool value)
        external
        onlyOwner
    {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[newPair] = value;

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

 



    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (
            !_isExcludedFromPayingMe[from] && !_isExcludedFromPayingMe[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
            if (automatedMarketMakerPairs[to]) {
                require(
                    amount <= HowManyNapkinsISell,
                    "You are exceeding maxSellAmount"
                );
            } else if (automatedMarketMakerPairs[from])
                require(
                    amount <= HowManyNapkinsIBuy,
                    "You are exceeding maxBuyAmount"
                );
            if (!_isExcludedFromMaxNapkins[to]) {
                require(
                    amount + balanceOf(to) <= maxNapkins,
                    "Unable to exceed Max Wallet"
                );
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 HowManyNapkinsWeGot = balanceOf(address(this));
        bool canSwap = HowManyNapkinsWeGot >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromPayingMe[from] &&
            !_isExcludedFromPayingMe[to]
        ) {
            swapping = true;

            if (totalSellTax > 0 && swapTokensAtAmount > 0) {
                swapMeYouDirtyBoi(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromPayingMe[from] || _isExcludedFromPayingMe[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (automatedMarketMakerPairs[to])
                feeAmt = (amount * totalSellTax) / 1000;
            else if (automatedMarketMakerPairs[from])
                feeAmt = (amount * totalBuyTax) / 1000;

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);
    }

    function swapMeYouDirtyBoi(uint256 tokens) private {
        uint256 toSwap = tokens; //- tokensToAddLiquidityWith;

        swapTokensForETH(toSwap);

        uint256 IsThereEthInHere = address(this).balance;

        uint256 devAmt = IsThereEthInHere;
        
        if (devAmt > 0) {
            (bool success, ) = payable(devWallet).call{value: devAmt}("");
            require(success, "Failed to send Eth");
        }

    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = thatthingthatswapstokens.WETH();

        _approve(address(this), address(thatthingthatswapstokens), tokenAmount);

        // make the swap
        thatthingthatswapstokens.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}
interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);

}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}