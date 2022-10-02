// SPDX-License-Identifier: MIT

/*
     __________
    | U good? |
    | ________|
    |/
                 __________
                | yesn't  |
                |________ |
                         \|
*/
pragma solidity >=0.8.8;
pragma experimental ABIEncoderV2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Yesnt is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public liquidityAddress;

    bool private swapping;

    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 public supply;

    address public marketingAddress;

    bool public tradingActive = false;
    bool public liquidityFeeActive = false;

    bool public limitsInEffect = true;
    bool public swapEnabled = true;

    bool public _renounceFeeFunctions = false;
    bool public _renounceMaxUpdateFunctions = false;
    bool public _renounceMarketMakerPairChanges = false;
    bool public _renounceWalletChanges = false;
    bool public _renounceExcludeInclude = false;

    uint256 public buyBurnFee;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyTotalFees;

    uint256 public sellBurnFee;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellTotalFees;

    uint256 public feeUnits = 100;

    uint256 public tokensForBurn;
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;

    uint256 private _previousBuyLiquidityFee = 0;
    uint256 private _previousSellLiquidityFee = 0;

    uint256 public maxWalletTotal;
    uint256 public maxSellTransaction;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxSellTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event updateHolderLastTransferTimestamp(
        address indexed account,
        uint256 timestamp
    );

    constructor() ERC20("Yesnt", "Yesnt") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxSellTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxSellTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1_000_000 * (10**18);
        supply += totalSupply;

        maxWallet = 2;
        maxSellTransaction = 1;

        maxSellTransactionAmount = (supply * maxSellTransaction) / 100; // 1%
        swapTokensAtAmount = (supply * 5) / 1000; // 0.5% swap wallet;
        maxWalletTotal = (supply * maxWallet) / 100; // 2%

        buyBurnFee = 0;
        buyMarketingFee = 3;
        buyLiquidityFee = 2;
        buyTotalFees = buyBurnFee + buyMarketingFee + buyLiquidityFee;

        sellBurnFee = 2;
        sellMarketingFee = 3;
        sellLiquidityFee = 2;
        sellTotalFees = sellBurnFee + sellMarketingFee + sellLiquidityFee;

        marketingAddress = 0x4aE9e1562e09F0482353D7840303570646d5536b;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxSellTransaction(owner(), true);
        excludeFromMaxSellTransaction(address(this), true);
        excludeFromMaxSellTransaction(address(0xdead), true);

        _approve(owner(), address(uniswapV2Router), totalSupply);
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function toggleLiquidityFeeActive() external onlyOwner {
        require(
            !_renounceFeeFunctions,
            "Cannot update fees after renouncemennt"
        );
        if (liquidityFeeActive) {
            _previousBuyLiquidityFee = buyLiquidityFee;
            _previousSellLiquidityFee = sellLiquidityFee;
        }
        buyLiquidityFee = liquidityFeeActive ? 0 : _previousBuyLiquidityFee;
        sellLiquidityFee = liquidityFeeActive ? 0 : _previousSellLiquidityFee;
        liquidityFeeActive = !liquidityFeeActive;
    }

    function enableTrading() external onlyOwner {
        buyBurnFee = 0;
        buyMarketingFee = 3;
        buyLiquidityFee = 2;
        buyTotalFees = buyBurnFee + buyMarketingFee + buyLiquidityFee;

        sellBurnFee = 2;
        sellMarketingFee = 3;
        sellLiquidityFee = 2;
        sellTotalFees = sellBurnFee + sellMarketingFee + sellLiquidityFee;

        tradingActive = true;
        liquidityFeeActive = true;
    }

    function updateMaxSellTransaction(uint256 newNum) external onlyOwner {
        require(
            !_renounceMaxUpdateFunctions,
            "Cannot update max transaction amount after renouncement"
        );
        require(newNum >= 1);
        maxSellTransaction = newNum;
        updateLimits();
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(
            !_renounceMaxUpdateFunctions,
            "Cannot update max transaction amount after renouncement"
        );
        require(newNum >= 1);
        maxWallet = newNum;
        updateLimits();
    }

    function excludeFromMaxSellTransaction(address updAds, bool isEx)
    public
    onlyOwner
    {
        require(
            !_renounceMaxUpdateFunctions,
            "Cannot update max transaction amount after renouncement"
        );
        _isExcludedMaxSellTransactionAmount[updAds] = isEx;
    }

    // if want fractional % in future, need to increase the fee units
    function updateFeeUnits(uint256 newNum) external onlyOwner {
        require(
            !_renounceFeeFunctions,
            "Cannot update fees after renouncement"
        );
        feeUnits = newNum;
    }

    function updateBuyFees(
        uint256 _burnFee,
        uint256 _marketingFee,
        uint256 _buyLiquidityFee
    ) external onlyOwner {
        require(
            !_renounceFeeFunctions,
            "Cannot update fees after renouncement"
        );
        buyBurnFee = _burnFee;
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyBurnFee + buyMarketingFee + buyLiquidityFee;
        require(
            buyTotalFees <= (15 * feeUnits) / 100,
            "Must keep fees at 15% or less"
        );
    }

    function updateSellFees(
        uint256 _burnFee,
        uint256 _marketingFee,
        uint256 _sellLiquidityFee
    ) external onlyOwner {
        require(
            !_renounceFeeFunctions,
            "Cannot update fees after renouncement"
        );
        sellBurnFee = _burnFee;
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellBurnFee + sellMarketingFee + sellLiquidityFee;
        require(
            sellTotalFees <= (25 * feeUnits) / 100,
            "Must keep fees at 25% or less"
        );
    }

    function updateMarketingAddress(address newWallet) external onlyOwner {
        require(
            !_renounceWalletChanges,
            "Cannot update wallet after renouncement"
        );
        marketingAddress = newWallet;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            !_renounceExcludeInclude,
            "Cannot update excluded accounts after renouncement"
        );
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function includeInFees(address account) public onlyOwner {
        require(
            !_renounceExcludeInclude,
            "Cannot update excluded accounts after renouncement"
        );
        excludeFromFees(account, false);
    }

    function setLiquidityAddress(address newAddress) public onlyOwner {
        require(
            !_renounceWalletChanges,
            "Cannot update wallet after renouncement"
        );
        liquidityAddress = newAddress;
    }

    function updateLimits() private {
        maxSellTransactionAmount = (supply * maxSellTransaction) / 100;
        swapTokensAtAmount = (supply * 5) / 10000; // 0.05% swap wallet;
        maxWalletTotal = (supply * maxWallet) / 100;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
    {
        require(
            !_renounceMarketMakerPairChanges,
            "Cannot update market maker pairs after renouncement"
        );
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

                // add the wallet to the _holderLastTransferTimestamp(address, timestamp) map
                _holderLastTransferTimestamp[tx.origin] = block.timestamp;
                emit updateHolderLastTransferTimestamp(
                    tx.origin,
                    block.timestamp
                );

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxSellTransactionAmount[to] &&
                    !automatedMarketMakerPairs[to]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletTotal,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxSellTransactionAmount[from] &&
                    !automatedMarketMakerPairs[from]
                ) {
                    require(
                        amount <= maxSellTransactionAmount,
                        "Sell transfer amount exceeds the maxSellTransactionAmount."
                    );
                } else if (!_isExcludedMaxSellTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWalletTotal,
                        "Max wallet exceeded"
                    );
                }
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
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
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(feeUnits);
                tokensForBurn += (fees * sellBurnFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                if (liquidityFeeActive) {
                    tokensForLiquidity +=
                    (fees * sellLiquidityFee) /
                    sellTotalFees;
                }
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(feeUnits);
                tokensForBurn += (fees * buyBurnFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                if (liquidityFeeActive) {
                    tokensForLiquidity +=
                    (fees * buyLiquidityFee) /
                    buyTotalFees;
                }
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                if (tokensForBurn > 0) {
                    _burn(address(this), tokensForBurn);
                    supply = totalSupply();
                    updateLimits();
                    tokensForBurn = 0;
                }
            }
            if (tokensForLiquidity > 0) {
                super._transfer(
                    address(this),
                    uniswapV2Pair,
                    tokensForLiquidity
                );
                tokensForLiquidity = 0;
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function renounceFeeFunctions() public onlyOwner {
        require(
            msg.sender == owner(),
            "Only the owner can renounce fee functions"
        );
        _renounceFeeFunctions = true;
    }

    function renounceWalletChanges() public onlyOwner {
        require(
            msg.sender == owner(),
            "Only the owner can renounce wallet changes"
        );
        _renounceWalletChanges = true;
    }

    function renounceMaxUpdateFunctions() public onlyOwner {
        require(
            msg.sender == owner(),
            "Only the owner can renounce max update functions"
        );
        _renounceMaxUpdateFunctions = true;
    }

    function renounceMarketMakerPairChanges() public onlyOwner {
        require(
            msg.sender == owner(),
            "Only the owner can renounce market maker pair changes"
        );
        _renounceMarketMakerPairChanges = true;
    }

    function renounceExcludeInclude() public onlyOwner {
        require(
            msg.sender == owner(),
            "Only the owner can renounce exclude include"
        );
        _renounceExcludeInclude = true;
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

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);

        tokensForMarketing = 0;

        (success, ) = address(marketingAddress).call{
        value: address(this).balance
        }("");
    }
}