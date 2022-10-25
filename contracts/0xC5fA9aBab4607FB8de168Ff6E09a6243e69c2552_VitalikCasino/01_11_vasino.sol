/**

♠ Vitalik Casino ♠
   ♣ $VASINO ♣

Web3 Casino Games

Website:
https://vitalik.casino

Telegram:
https://t.me/vasinoportal

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16; 

/**      openzeppelin/contracts      */
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

/**      uniswap/v2-core.     */
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol"; 
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol"; 
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 

contract VitalikCasino is ERC20, Ownable {
    using SafeMath for uint256; 

    IUniswapV2Router02 public immutable uniswapV2Router; 
    address public immutable uniswapV2Pair; 

    bool private swapping; 

    uint256 public swapTokensAtAmount; 
    uint256 public maxTxAmount; 

    bool public tradingActive = false; 
    bool public limitsInEffect = true; 
    bool public swapEnabled = false; 

    address public casinoWallet; 

    uint256 public constant feeDivisor = 1000; 

    uint256 public casinoBuyFee; 
    uint256 public totalBuyFees; 

    uint256 public casinoSellFee; 
    uint256 public totalSellFees; 

    uint256 public tokensForFees; 
    uint256 public tokensForCasino; 

    // launch block number
    uint256 launchBlockNumber;

    bool public transferDelayEnabled = true; 
    uint256 public maxWallet; 

    // maggings
    mapping(address => bool) private _blacklist; 
    mapping(address => bool) private _isExcludedFromFees; 
    mapping(address => bool) public _isExcludedMaxTransactionAmount; 
    mapping(address => bool) public automatedMarketMakerPairs; 

    event ExcludeFromFees(address indexed account, bool isExcluded); 
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded); 

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value); 

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    ); 

    constructor() ERC20("Vitalik Casino", "VASINO") {

        casinoWallet = address(0xCe3BAB9741bAE4aaD49915eDcC2F42Cfaca1fF56);

        uint256 totalSupply = 1 * 1e9 * 1e18; 

        swapTokensAtAmount = (totalSupply * 1) / 10000;  // 0.01% swap tokens amount
        maxTxAmount = (totalSupply * 10) / 1000;  // 1% maxTxAmountTxn
        maxWallet = (totalSupply * 20) / 1000;  // 2% maxWallet

        casinoBuyFee = 40;  // 4%
        totalBuyFees = casinoBuyFee;  

        casinoSellFee = 50;  // 5%
        totalSellFees = casinoSellFee; 

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
        excludeFromFees(address(casinoWallet), true); 

        excludeFromMaxTransaction(owner(), true); 
        excludeFromMaxTransaction(address(this), true); 
        excludeFromMaxTransaction(address(0xdead), true); 
        excludeFromMaxTransaction(address(casinoWallet), true); 

        _mint(address(owner()), totalSupply); 
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Can not re-enable trading"); 
        tradingActive = true; 
        swapEnabled = true; 
        launchBlockNumber = block.number;
    }

    function updateMaxTx(uint256 _val) external onlyOwner {
        require(
            _val >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxTxAmount lower than 1%."
        ); 
        maxTxAmount = _val * (10**18); 
    }

    function updateMaxWallet(uint256 _val) external onlyOwner {
        require(
            _val >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxWallet lower than 1%."
        ); 
        maxWallet = _val * (10**18); 
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

    function updateSellFees(uint256 _casinoSellFee) external onlyOwner {
        casinoSellFee = _casinoSellFee; 
        totalSellFees = casinoSellFee; 
        require(totalSellFees <= 100, "Must keep fees at 10% or less"); 
    }

    function updateBuyFees(uint256 _casinoBuyFee) external onlyOwner {
        casinoBuyFee = _casinoBuyFee; 
        totalBuyFees = casinoBuyFee; 
        require(totalSellFees <= 150, "Must keep fees at 15% or less"); 
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded; 

        emit ExcludeFromFees(account, excluded); 
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {
        for (uint256 i = 0;  i < accounts.length;  i++) {
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

                // buying
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTxAmount + 1 * 1e18,
                        "Buy transfer amount exceeds the maxTxAmount."
                    ); 
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    ); 
                }
                // selling
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTxAmount + 1 * 1e18,
                        "Sell transfer amount exceeds the maxTxAmount."
                    ); 
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    ); 
                }
            }
        }

        // Anti-bot - blacklist snipers
        if (block.number <= (launchBlockNumber + 1) && 
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

        bool takeFees = !swapping; 

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFees = false; 
        }

        uint256 fees = 0; 

        // no taxes on transfers (non buys/sells) 
        if (takeFees) {
            // on sell take fees, purchase token and burn it
            if (automatedMarketMakerPairs[to] && totalSellFees > 0) {
                fees = amount.mul(totalSellFees).div(feeDivisor); 
                tokensForFees += fees; 
                tokensForCasino += (fees * casinoSellFee) / totalSellFees; 
            }
            // on buy 
            else if (automatedMarketMakerPairs[from]) {
                fees = amount.mul(totalBuyFees).div(feeDivisor); 
                tokensForFees += fees; 
                tokensForCasino += (fees * casinoBuyFee) / totalBuyFees; 
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

    // remove limits after token is stable.
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false; 
        return true; 
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this)); 
        uint256 totalTokensToSwap = tokensForCasino; 
        bool success; 

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return; 
        }

        uint256 amountToSwapForETH = contractBalance; 
        swapTokensForEth(amountToSwapForETH); 

        (success, ) = address(casinoWallet).call{
            value: address(this).balance
        }(""); 

        tokensForCasino = 0; 
        tokensForFees = 0; 
    }

    function withdrawStuckEth() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }(""); 
        require(success, "failed to withdraw"); 
    }
}