/*         
      ___           ___           ___           ___       ___       ___           ___           ___           ___           ___     
     /\  \         /\__\         /\  \         /\__\     /\__\     /\  \         /\__\         /\  \         /\  \         /\__\    
    /::\  \       /:/  /        /::\  \       /:/  /    /:/  /    /::\  \       /:/ _/_       /::\  \       /::\  \       /::|  |   
   /:/\:\  \     /:/__/        /:/\:\  \     /:/  /    /:/  /    /:/\:\  \     /:/ /\__\     /:/\:\  \     /:/\:\  \     /:|:|  |   
  /:/  \:\__\   /::\  \ ___   /::\~\:\  \   /:/  /    /:/  /    /:/  \:\  \   /:/ /:/ _/_   /::\~\:\  \   /::\~\:\  \   /:/|:|  |__ 
 /:/__/ \:|__| /:/\:\  /\__\ /:/\:\ \:\__\ /:/__/    /:/__/    /:/__/ \:\__\ /:/_/:/ /\__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/ |:| /\__\
 \:\  \ /:/  / \/__\:\/:/  / \/__\:\/:/  / \:\  \    \:\  \    \:\  \ /:/  / \:\/:/ /:/  / \:\~\:\ \/__/ \:\~\:\ \/__/ \/__|:|/:/  /
  \:\  /:/  /       \::/  /       \::/  /   \:\  \    \:\  \    \:\  /:/  /   \::/_/:/  /   \:\ \:\__\    \:\ \:\__\       |:/:/  / 
   \:\/:/  /        /:/  /        /:/  /     \:\  \    \:\  \    \:\/:/  /     \:\/:/  /     \:\ \/__/     \:\ \/__/       |::/  /  
    \::/__/        /:/  /        /:/  /       \:\__\    \:\__\    \::/  /       \::/  /       \:\__\        \:\__\         /:/  /   
     ~~            \/__/         \/__/         \/__/     \/__/     \/__/         \/__/         \/__/         \/__/         \/__/        
                                                                                            
    🎃  It’s a DHalloween party! 
    🍬  De-Trick or treat with other Degens.
    🧛  Join the De-Costume Party.
    🪓  Participate in the DHalloween Murder Mystery.

    🎁  Earn rewards through de-trick or treating, and 
        participating in the de-costume party.

    💸  A chunk of the fees will be used for buyback burns.

    👻  dhalloween.net  
    🧟‍♀️  t.me/dhalloween

    @DegenerateToolsApe: 
    *This is a Halloween festive launch purely for degen entertainment purposes.*
*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";   
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";     
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";     
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";     

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}


contract DegenHalloween is ERC20, Ownable {
    using SafeMath for uint256;

    string[] public draftOrder = [
        "Mario", "Bowser", "Peach", "Yoshi", "Donkey Kong",
        "Captain Falcon", "Fox", "Ness", "Ice Climbers",
        "Kirby", "Samus", "Zelda", "Link", "Pikachu",
        "Jigglypuff", "Dr. Mario", "Luigi", "Ganondorf",
        "Falco", "Young Link", "Pichu", "Mewtwo",
        "Mr. Game & Watch", "Marth", "Roy"];
    uint private draftCount = 0;
    uint256 private antiSnipeBlocks;
    mapping(address => string) public costumes;

    string[] public trickOrTreatWinners;
    string[] public murderMysteryWinners;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;

    uint256 public swapTokensAtAmount;
    uint256 public maxTransactionAmount;

    uint256 public liquidityActiveBlock = 0; // 0 means liquidity is not active yet
    uint256 public tradingActiveBlock = 0; // 0 means trading is not active

    bool public tradingActive = false;
    bool public limitsInEffect = true;
    bool public swapEnabled = false;

    address public constant burnWallet = 0x000000000000000000000000000000000000dEaD;

    address public dhalloweenWallet = address(0x14f83880cfF575eCCf7DEAD696c45aA608A18722);

    uint256 public constant feeDivisor = 1000;

    uint256 public dhalloweenBuyFee;
    uint256 public totalBuyFees;

    uint256 public dhalloweenSellFee;
    uint256 public totalSellFees;

    uint256 public tokensForFees;
    uint256 public tokensForDhalloween;

    bool public transferDelayEnabled = true;
    uint256 public maxWallet;

    mapping(address => bool) private _blacklist;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(address => uint256) public _earlyBuyer;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() ERC20("DeTrick or Treat", "DHALLOWEEN") {
        uint256 totalSupply = 1 * 1e9 * 1e18;

        swapTokensAtAmount = (totalSupply * 1) / 10000; // 0.01% swap tokens amount
        maxTransactionAmount = (totalSupply * 10) / 1000; // 1% maxTransactionAmountTxn
        maxWallet = (totalSupply * 20) / 1000; // 2% maxWallet

        dhalloweenBuyFee = 60; 
        totalBuyFees = dhalloweenBuyFee; 

        dhalloweenSellFee = 60; 
        totalSellFees = dhalloweenSellFee;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(_uniswapV2Router), true);
        excludeFromFees(address(dhalloweenWallet), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(dhalloweenWallet), true);

        _mint(address(owner()), totalSupply);
    }

    receive() external payable {}

    function enableTrading(uint256 _antiSnipeBlocks) external onlyOwner {
        require(!tradingActive, "Cannot re-enable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        antiSnipeBlocks = _antiSnipeBlocks;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
           newNum * (10**18) > maxTransactionAmount,
            "Cannot set maxTransactionAmount lower than previous value"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum * (10**18) > maxWallet,
            "Cannot set maxWallet lower than previous value"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateSellFees(uint256 _dhalloweenSellFee) external onlyOwner {
        dhalloweenSellFee = _dhalloweenSellFee;
        totalSellFees = dhalloweenSellFee;
        require(totalSellFees <= 150, "Must keep fees at 15% or less");
    }

    function updateBuyFees(uint256 _dhalloweenBuyFee) external onlyOwner {
        dhalloweenBuyFee = _dhalloweenBuyFee;
        totalBuyFees = dhalloweenBuyFee;
        require(totalBuyFees <= 150, "Must keep fees at 15% or less");
    }


    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function updateTrickOrTreatWinners(string[] memory _winners)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _winners.length; i++) {
            trickOrTreatWinners.push(_winners[i]);
        }
    }

    function updateMurderMysteryWinners(string[] memory _winners)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _winners.length; i++) {
            murderMysteryWinners.push(_winners[i]);
        }
    }

    function trickOrTreatWinnersCount() external view returns (uint) {
        return trickOrTreatWinners.length;
    }

    function murderMysteryWinnersCount() external view returns (uint) {
        return murderMysteryWinners.length;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !_blacklist[to] && !_blacklist[from],
            "You have been blacklisted from transfering tokens"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active yet."
            );
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
                        amount <= maxTransactionAmount + 1 * 1e18,
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
                        amount <= maxTransactionAmount + 1 * 1e18,
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

        // anti-bot 
        if (
            block.number < (tradingActiveBlock + antiSnipeBlocks) &&
            to != uniswapV2Pair &&
            to != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
        ) {
            _blacklist[to] = true;
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

        // no taxes on transfers (non buys/sells)
        if (takeFee) {
            // on sell take fees, purchase token and burn it
            if (automatedMarketMakerPairs[to] && totalSellFees > 0) {
                fees = amount.mul(totalSellFees).div(feeDivisor);
                tokensForFees += fees;
                tokensForDhalloween += (fees * dhalloweenSellFee) / totalSellFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from]) {
                fees = amount.mul(totalBuyFees).div(feeDivisor);
                tokensForFees += fees;
                tokensForDhalloween += (fees * dhalloweenBuyFee) / totalBuyFees;

                costumes[to] = draftOrder[draftCount % draftOrder.length];
                draftCount += 1;

            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }


        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
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
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForDhalloween;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        uint256 amountToSwapForETH = contractBalance;
        swapTokensForEth(amountToSwapForETH);

        (success, ) = address(dhalloweenWallet).call{
            value: address(this).balance
        }("");

        tokensForDhalloween = 0;
        tokensForFees = 0;
    }

    function changeAccountStatus(address[] memory bots_, bool status)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < bots_.length; i++) {
            _blacklist[bots_[i]] = status;
        }
    }

    function withdrawStuckEth() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "failed to withdraw");
    }
}