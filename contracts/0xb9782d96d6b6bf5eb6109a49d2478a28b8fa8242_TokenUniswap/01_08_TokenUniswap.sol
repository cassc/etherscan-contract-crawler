// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// interface ITurnstile {
//     function assign(
//         uint256 beneficiaryTokenID
//     ) external returns (uint256 beneficiaryTokenID_);

//     function getTokenId(address _smartContract) external view returns (uint256);
// }

interface SwapV2Router {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface SwapV2Factory {
    // function turnstile() external view returns (ITurnstile);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address);
}

contract TokenUniswap is ERC20, Ownable {
    using SafeMath for uint256;

    SwapV2Router public immutable swapV2Router;
    //ITurnstile public immutable turnstile;
    address public immutable swapV2Pair;
    address public constant DEAD = address(0xdead);

    bool private swapping;

    address public revShareWallet;
    address public devWallet;

    uint256 public maxTradingAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 constant FEE_BASE = 1000; //
    uint256 constant GEN_FEE = 3; // fee for GEN Bot: 0.3%
    address constant GEN_WALLET = 0x91FEad7F2B2172e75FfCf4cAdFF5049c9270EE41;

    uint256 public buyTotalFees; // buy fee
    uint256 public sellTotalFees; // sell fee

    // Tax distribution
    uint256 public burnFee;
    uint256 public devFee;
    uint256 public revShareFee;

    uint256 public tokensForGen;
    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTradingAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event revShareWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(
        address routerAddress,
        string memory name,
        string memory symbol,
        uint256 totalSupply_
    ) ERC20(name, symbol) {
        SwapV2Router router = SwapV2Router(routerAddress);
        SwapV2Factory factory = SwapV2Factory(router.factory());
        // turnstile = factory.turnstile();
        // uint256 csrTokenID = turnstile.getTokenId(address(factory));
        // turnstile.assign(csrTokenID);
        swapV2Router = router;
        // create pair This:ETH
        swapV2Pair = factory.createPair(address(this), router.WETH());

        excludeFromMaxTrading(address(swapV2Pair), true);
        _setAutomatedMarketMakerPair(address(swapV2Pair), true);

        uint256 totalSupply = totalSupply_ * 1e18;
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05%

        maxTradingAmount = (totalSupply * 1) / 1000; // 0.1%
        maxWallet = (totalSupply * 10) / 1000; // 1%

        // Fee distribute: burn: 1, dev: 4
        updateTaxSplit(1, 4, 0, address(0));

        // 5% fee for buy/sell
        updateFees(50, 50);

        devWallet = msg.sender;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTrading(owner(), true);
        excludeFromMaxTrading(address(this), true);
        excludeFromMaxTrading(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function startNow() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTradingAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTradingAmount lower than 0.1%"
        );
        maxTradingAmount = newNum * (10 ** 18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxWallet lower than 1.0%"
        );
        maxWallet = newNum * (10 ** 18);
    }

    function excludeFromMaxTrading(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTradingAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateFees(
        uint256 buyTotalFees_,
        uint256 sellTotalFees_
    ) public onlyOwner {
        require(
            buyTotalFees_ <= 50 && sellTotalFees_ <= 50,
            "Buy/sell fees must be <= 50."
        );
        buyTotalFees = buyTotalFees_;
        sellTotalFees = sellTotalFees_;

        if (buyTotalFees < GEN_FEE) buyTotalFees += GEN_FEE;
        if (sellTotalFees < GEN_FEE) sellTotalFees += GEN_FEE;
    }

    // contract setting
    function updateTaxSplit(
        uint256 burnFee_,
        uint256 devFee_,
        uint256 revShareFee_,
        address revShareWallet_
    ) public onlyOwner {
        // tax distribution
        if (revShareFee_ > 0)
            require(
                revShareWallet_ != address(0),
                "Revshare Wallet is required!"
            );
        burnFee = burnFee_;
        devFee = devFee_;
        revShareFee = revShareFee_;

        // update revshare wallet
        revShareWallet = revShareWallet_;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != swapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateRevShareWallet(
        address newRevShareWallet
    ) external onlyOwner {
        emit revShareWalletUpdated(newRevShareWallet, revShareWallet);
        revShareWallet = newRevShareWallet;
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
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

                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTradingAmount[to]
                ) {
                    //when buy
                    require(
                        amount <= maxTradingAmount,
                        "Buy transfer amount exceeds the maxTradingAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                } else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTradingAmount[from]
                ) {
                    //when sell
                    require(
                        amount <= maxTradingAmount,
                        "Sell transfer amount exceeds the maxTradingAmount."
                    );
                } else if (!_isExcludedMaxTradingAmount[to]) {
                    //when transfer
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

        // only take free for trading
        bool takeFee = !swapping &&
            (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]);

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            tokensForGen += amount.mul(GEN_FEE).div(FEE_BASE);
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(FEE_BASE);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(FEE_BASE);
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
        path[1] = swapV2Router.WETH();

        _approve(address(this), address(swapV2Router), tokenAmount);

        // make the swap
        swapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swapV2Router), tokenAmount);

        // add the liquidity
        swapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _addLiquidity() external onlyOwner {
        addLiquidity(balanceOf(address(this)), address(this).balance);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > swapTokensAtAmount * 5) {
            contractBalance = swapTokensAtAmount * 5;
        }
        if (contractBalance == 0) return;

        uint256 totalTokensToSwap = contractBalance;

        if (tokensForGen > contractBalance) tokensForGen = contractBalance;

        if (burnFee > 0) {
            uint256 tokensToBurn = contractBalance
                .sub(tokensForGen)
                .mul(burnFee)
                .div(burnFee + devFee + revShareFee);
            if (tokensToBurn > 0) {
                // transfer to dead
                super._transfer(address(this), DEAD, tokensToBurn);
            }

            totalTokensToSwap = totalTokensToSwap.sub(tokensToBurn);
        }

        bool success;

        if (totalTokensToSwap == 0) return;

        swapTokensForEth(totalTokensToSwap);

        uint256 ethBalance = address(this).balance;

        if (tokensForGen > totalTokensToSwap) tokensForGen = totalTokensToSwap;

        uint256 ethForGen = ethBalance.mul(tokensForGen).div(totalTokensToSwap);
        uint256 ethForDev;
        uint256 ethForRevShare;
        ethBalance = ethBalance.sub(ethForGen);
        if (devFee + revShareFee > 0) {
            ethForDev = ethBalance.mul(devFee).div(devFee + revShareFee);
            ethForRevShare = ethBalance.sub(ethForDev);
        }

        // reset token to burn
        tokensForGen = 0;

        if (ethForGen > 0) {
            (success, ) = address(GEN_WALLET).call{value: ethForGen}("");
        }
        if (ethForDev > 0) {
            (success, ) = address(devWallet).call{value: ethForDev}("");
        }
        if (ethForRevShare > 0) {
            (success, ) = address(revShareWallet).call{value: ethForDev}("");
        }
    }

    function withdrawStuckToken(
        address _token,
        address _to
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }

    /************************************************************************/
}