/*
    OmniSniper provides professional grade dex trading tools to investors for free. 
    Connect to start using our snipers, scanners, and more!
*/

// WEBSITE: omnisniper.net
// TELEGRAM: t.me/omnisniper


// imports - @openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// imports - @uniswap/v2
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract OmniSniper is ERC20, Ownable {
    using SafeMath for uint256;

    // constructor vars
    IUniswapV2Router02 public immutable uniV2Router;
    address public immutable uniV2Pair;

    address public teamMarketingWallet; 

    bool private swapping;

    uint256 public swapTokensAtAmount;
    uint256 public maxTransactionAmount;

    uint256 public marketingBuySwapFee;
    uint256 public totalBuySwapFees;

    uint256 public marketingSellSwapFee;
    uint256 public totalSellSwapFees;

    uint256 public tknsForFees;
    uint256 public tknsForMarketing;

    uint256 public maxWalletSize;

    mapping(address => bool) private _bL;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;


    // non-constructor vars
    bool public tradingActive = false;
    bool public limitsInEffect = true;
    bool public swapEnabled = false;

    uint256 public constant feeDiv = 1000;

    bool public transferDelayEnabled = true;
    
    // events
    event SwapAndLiquify(
        uint256 tknsSwapped,
        uint256 ethReceived,
        uint256 tknsIntoLiqudity
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("OmniSniper", "OMNI") 
    {
        uint256 _maxSupply = 1 * 1e9 * 1e18;

        swapTokensAtAmount = (_maxSupply * 1) / 10000; // 0.01% swap tkns amount, fee threshold
        maxTransactionAmount = (_maxSupply * 10) / 1000; // 1% maxTransactionAmountTxn
        maxWalletSize = (_maxSupply * 10) / 1000; // 1% maxWalletSize

        marketingBuySwapFee = 30; // 3%
        marketingSellSwapFee = 30; // 3%
        totalBuySwapFees = marketingBuySwapFee; 
        totalSellSwapFees = marketingSellSwapFee;

        // set addrs
        teamMarketingWallet = msg.sender;
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Create a uni pair 
        address _uniV2Pair = IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        uniV2Router = _uniV2Router;
        uniV2Pair = _uniV2Pair;
        _setAutomatedMarketMakerPair(_uniV2Pair, true);

        // exclude from fees or max txn amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(_uniV2Router), true);
        excludeFromFees(address(teamMarketingWallet), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(teamMarketingWallet), true);

        _mint(address(owner()), _maxSupply);
    }

    receive() external payable {}

    function updateMaxTxnAmt(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.5%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmt(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWalletSize lower than 0.5%"
        );
        maxWalletSize = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateSellSwapFees(uint256 _marketingSellSwapFee) external onlyOwner {
        marketingSellSwapFee = _marketingSellSwapFee;
        totalSellSwapFees = marketingSellSwapFee;
        require(totalSellSwapFees <= 50, "Must keep sell fees at 5% or less");
    }

    function updateBuySwapFees(uint256 _marketingBuySwapFee) external onlyOwner {
        marketingBuySwapFee = _marketingBuySwapFee;
        totalBuySwapFees = marketingBuySwapFee;
        require(totalBuySwapFees <= 50, "Must keep buy fees at 5% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(
            pair != uniV2Pair,
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

    function commenceTrading() external onlyOwner {
        require(!tradingActive, "Trading is already enabled");
        tradingActive = true;
        swapEnabled = true;
    }

    function updateWalletFlag(bool _flag, address[] calldata addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _bL[addrs[i]] = _flag;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_bL[to] && !_bL[from], "Wallet is blacklisted");

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
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
                if (!tradingActive) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                // when buying
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount <= maxTransactionAmount + 1 * 1e18,
                        "Buy txn transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletSize,
                        "Max wallet exceeded"
                    );
                }
                // when selling
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(
                        amount <= maxTransactionAmount + 1 * 1e18,
                        "Sell txn transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWalletSize,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        // check if enough tkns are available for swap
        uint256 contractTokenBal = balanceOf(address(this));
        bool validSwap = contractTokenBal >= swapTokensAtAmount;
        if (validSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
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

        // takeFees ensures no fee on token transfers
        if (takeFees) {
            // on sell txn
            if (automatedMarketMakerPairs[to] && totalSellSwapFees > 0) {
                fees = amount.mul(totalSellSwapFees).div(feeDiv);
                tknsForFees += fees;
                tknsForMarketing += (fees * marketingSellSwapFee) / totalSellSwapFees;
            }
            // on buy txn
            else if (automatedMarketMakerPairs[from]) {
                fees = amount.mul(totalBuySwapFees).div(feeDiv);
                tknsForFees += fees;
                tknsForMarketing += (fees * marketingBuySwapFee) / totalBuySwapFees;
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // uniswap v2 token swap path
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();

        // approve contract:univ2router for swap
        _approve(address(this), address(uniV2Router), tokenAmount);

        // swap txn
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniV2Router), tokenAmount);

        // add the liquidity
        uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    // removes max wallet and max txn
    function removeSwapLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tknsForMarketing;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        uint256 amountToSwapForETH = contractBalance;
        swapTokensForEth(amountToSwapForETH);

        (success, ) = address(teamMarketingWallet).call{
            value: address(this).balance
        }("");

        tknsForMarketing = 0;
        tknsForFees = 0;
    }

    // removes eth stuck incase user accidently sends ETH into contract
    function withdrawStuckEth() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "failed to withdraw");
    }
}