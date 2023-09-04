// SPDX-License-Identifier: UNLICENSED

/*



 __       __   ______  ________   ______   __    __  ________  _______  
|  \  _  |  \ /      \|        \ /      \ |  \  |  \|        \|       \ 
| $$ / \ | $$|  $$$$$$\\$$$$$$$$|  $$$$$$\| $$  | $$| $$$$$$$$| $$$$$$$\
| $$/  $\| $$| $$__| $$  | $$   | $$   \$$| $$__| $$| $$__    | $$__| $$
| $$  $$$\ $$| $$    $$  | $$   | $$      | $$    $$| $$  \   | $$    $$
| $$ $$\$$\$$| $$$$$$$$  | $$   | $$   __ | $$$$$$$$| $$$$$   | $$$$$$$\
| $$$$  \$$$$| $$  | $$  | $$   | $$__/  \| $$  | $$| $$_____ | $$  | $$
| $$$    \$$$| $$  | $$  | $$    \$$    $$| $$  | $$| $$     \| $$  | $$
 \$$      \$$ \$$   \$$   \$$     \$$$$$$  \$$   \$$ \$$$$$$$$ \$$   \$$
                                                                        
                                                                        
                                                                    

https://t.me/watchertech
https://twitter.com/WatcherCoinEth
https://watcher.watch

*/                  


pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./SafeMath.sol";



contract Watcher is ERC20, Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 private launchedAt;
    uint256 private launchedTime;
    uint256 public deadBlocks;

    uint256 public buyTotalFees;
    uint256 private buyMarketingFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;

    uint256 public tokensForMarketing;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(address _wallet1) ERC20("Watcher", "$WATCHER") {
        uint256 totalSupply = 420_000_000_000_000 * 1e9;

        maxTransactionAmount = 420_000_000_000_000 * 1e9;
        maxWallet = 420_000_000_000_000 * 1e9;
        swapTokensAtAmount = maxTransactionAmount / 20000;
        marketingWallet = _wallet1;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableUniswapPair() external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _approve(address(this), address(uniswapV2Router), totalSupply());
        excludeFromMaxTransaction(address(uniswapV2Router), true);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
            
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
    }

    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        deadBlocks = _deadBlocks;
        tradingActive = true;
        swapEnabled = true;
        launchedAt = block.number;
        launchedTime = block.timestamp;
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount_)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount_ >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount_ <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount_;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum_) external onlyOwner {
        require(
            newNum_ >= ((totalSupply() * 1) / 1000) / 1e9,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum_ * (10**9);
    }

    function updateMaxWalletAmount(uint256 newNum_) external onlyOwner {
        require(
            newNum_ >= ((totalSupply() * 5) / 1000) / 1e9,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum_ * (10**9);
    }

    function whitelistContract(address _whitelist,bool isWL_)
    public
    onlyOwner
    {
      _isExcludedMaxTransactionAmount[_whitelist] = isWL_;

      _isExcludedFromFees[_whitelist] = isWL_;

    }

    function excludeFromMaxTransaction(address updAds_, bool isEx_)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds_] = isEx_;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled_) external onlyOwner {
        swapEnabled = enabled_;
    }

    function excludeFromFees(address account_, bool excluded_) public onlyOwner {
        _isExcludedFromFees[account_] = excluded_;
        emit ExcludeFromFees(account_, excluded_);
    }

    function manualswap(uint256 amount_) external {
      require(_msgSender() == marketingWallet);
        require(amount_ <= balanceOf(address(this)) && amount_ > 0, "Wrong amount");
        swapTokensForEth(amount_);
    }

    function manualsend() external {
        bool success;
        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

        function setAutomatedMarketMakerPair(address pair_, bool value_)
        public
        onlyOwner
    {
        require(
            pair_ != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair_, value_);
    }

    function _setAutomatedMarketMakerPair(address pair_, bool value_) private {
        automatedMarketMakerPairs[pair_] = value_;

        emit SetAutomatedMarketMakerPair(pair_, value_);
    }

    function updateBuyFees(
        uint256 _marketingFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyTotalFees = buyMarketingFee;
        require(buyTotalFees <= 5, "Must keep fees at 5% or less");
    }

    function updateSellFees(
        uint256 _marketingFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellTotalFees = sellMarketingFee;
        require(sellTotalFees <= 5, "Must keep fees at 5% or less");
    }

    function updateMarketingWallet(address newMarketingWallet_)
        external
        onlyOwner
    {
        emit marketingWalletUpdated(newMarketingWallet_, marketingWallet);
        marketingWallet = newMarketingWallet_;
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

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
              if
                ((launchedAt + deadBlocks) >= block.number)
              {
                buyMarketingFee = 99;
                buyTotalFees = buyMarketingFee;

                sellMarketingFee = 99;
                sellTotalFees = sellMarketingFee;

              } else if(block.number > (launchedAt + deadBlocks) && block.number <= launchedAt + 30)
              {
                maxTransactionAmount =  8_400_000_000_000  * 1e9;
                maxTransactionAmount =  8_400_000_000_000  * 1e9;

                buyMarketingFee = 30;
                buyTotalFees = buyMarketingFee;

                sellMarketingFee = 30;
                sellTotalFees = sellMarketingFee;
              }

                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                //when buy
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
                //when sell
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

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount_) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount_);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount_,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap =
            tokensForMarketing;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens 

        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        tokensForMarketing = 0;


        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

}