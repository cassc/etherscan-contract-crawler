// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./UniswapV2PriceImpactCalculator.sol";
import "./BiggestBuyer.sol";
import "./ChameleonDividendTracker.sol";
import "./ChameleonStorage.sol";
import "./IUniswapV2Router.sol";
import "./IMysteryContract.sol";

library Fees {
    struct Data {
        address uniswapV2Pair;
        uint256 baseFee;//in 100ths of a percent
        uint256 extraFee;//in 100ths of a percent, extra sell fees. Buy fee is baseFee - extraFee
        uint256 extraFeeUpdateTime; //when the extraFee was updated. Use time elapsed to dynamically calculate new fee

        uint256 feeSellImpact; //in 100ths of a percent, how much price impact on sells (in percent) increases extraFee.
        uint256 feeTimeImpact; //in 100ths of a percent, how much time elapsed (in minutes) lowers extraFee

        uint256 dividendsPercent; //80% of fees go to dividends
        uint256 marketingPercent; //20% of fees go to marketing
        uint256 mysteryPercent; //0% of fees go to mystery contract... for now
    }

    uint256 private constant FACTOR_MAX = 10000;

    event UpdateBaseFee(uint256 value);
    event UpdateFeeSellImpact(uint256 value);
    event UpdateFeeTimeImpact(uint256 value);

    event UpdateFeeDestinationPercents(
        uint256 dividendsPercent,
        uint256 marketingPercent,
        uint256 mysteryPercent
    );


    event BuyWithFees(
        address indexed account,
        int256 feeFactor,
        int256 feeTokens,
        uint256 referredBonus,
        uint256 referralBonus,
        address referrer
    );

    event SellWithFees(
        address indexed account,
        uint256 feeFactor,
        uint256 feeTokens
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToMarketing1(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToMarketing2(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToMystery(
        uint256 tokensSwapped,
        uint256 amount
    );

    function init(
        Data storage data,
        ChameleonStorage.Data storage _storage,
        address uniswapV2Pair) public {
        data.uniswapV2Pair = uniswapV2Pair;
        updateBaseFee(data, 1000); //10% base fee
        updateFeeSellImpact(data, 100); //each 1% price impact on sells will increase sell fee 1%, and lower buy fee 1%
        updateFeeTimeImpact(data, 100); //extra sell fee lowers 1% every minute, and buy fee increases 1% every minute until back to base fee

        updateFeeDestinationPercents(data, _storage, 75, 25, 0);
    }

    function updateBaseFee(Data storage data, uint256 value) public {
        require(value >= 300 && value <= 1000, "invalid base fee");
        data.baseFee = value;
        emit UpdateBaseFee(value);
    }

    function updateFeeSellImpact(Data storage data, uint256 value) public {
        require(value >= 10 && value <= 500, "invalid fee sell impact");
        data.feeSellImpact = value;
        emit UpdateFeeSellImpact(value);
    }

    function updateFeeTimeImpact(Data storage data, uint256 value) public {
        require(value >= 10 && value <= 500, "invalid fee time impact");
        data.feeTimeImpact = value;
        emit UpdateFeeSellImpact(value);
    }

    function updateFeeDestinationPercents(Data storage data, ChameleonStorage.Data storage _storage, uint256 dividendsPercent, uint256 marketingPercent, uint256 mysteryPercent) public {
        require(dividendsPercent + marketingPercent + mysteryPercent == 100, "invalid percents");
        require(dividendsPercent >= 50, "invalid percent");

        if(address(_storage.mysteryContract) == address(0)) {
            require(mysteryPercent == 0, "invalid percent");
        }

        data.dividendsPercent = dividendsPercent;
        data.marketingPercent = marketingPercent;
        data.mysteryPercent = mysteryPercent;

        emit UpdateFeeDestinationPercents(dividendsPercent, marketingPercent, mysteryPercent);
    }


    //Gets fees in 100ths of a percent for buy and sell (anything else is always base fee)
    //and also returns current timestamp
    function getCurrentFees(Data storage data) public view returns (int256, uint256) {
        uint256 timeElapsed = block.timestamp - data.extraFeeUpdateTime;

        uint256 timeImpact = data.feeTimeImpact * timeElapsed / 60;

        //Enough time has passed that fees are back to base
        if(timeImpact >= data.extraFee) {
            return (int256(data.baseFee), data.baseFee);
        }

        uint256 realExtraFee = data.extraFee - timeImpact;

        int256 buyFee = int256(data.baseFee) - int256(realExtraFee);
        uint256 sellFee = data.baseFee + realExtraFee;

        return (buyFee, sellFee);
    }

    function handleSell(Data storage data, uint256 amount) public
        returns (uint256) {
        (,uint256 sellFee) = getCurrentFees(data);

        uint256 priceImpact = UniswapV2PriceImpactCalculator.calculateSellPriceImpact(address(this), data.uniswapV2Pair, amount);

        uint256 increaseSellFee = priceImpact * data.feeSellImpact / 100;

        sellFee = sellFee + increaseSellFee;

        //max 30% so it is always sellable with 49% slippage on Uniswap
        if(sellFee >= 3000) {
            sellFee = 3000;
        }

        data.extraFee = sellFee - data.baseFee;
        data.extraFeeUpdateTime = block.timestamp;

        return sellFee;
    }

    function calculateFees(uint256 amount, uint256 feeFactor) public pure returns (uint256) {
        if(feeFactor > FACTOR_MAX) {
            feeFactor = FACTOR_MAX;
        }
        return amount * uint256(feeFactor) / FACTOR_MAX;
    }

    function swapTokensForEth(uint256 tokenAmount, IUniswapV2Router02 router)
        private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAccumulatedFees(Data storage data, ChameleonStorage.Data storage _storage, uint256 tokenAmount) public {
        swapTokensForEth(tokenAmount, _storage.router);
        uint256 balance = address(this).balance;

        uint256 dividends = balance * data.dividendsPercent / 100;
        uint256 marketing = balance * data.marketingPercent / 100;
        uint256 mystery = balance - dividends - marketing;

        if(data.mysteryPercent == 0) {
            mystery = 0;
        }

        bool success;

        (success,) = address(_storage.dividendTracker).call{value: dividends}("");

        if(success) {
            emit SendDividends(tokenAmount, dividends);
        }

        uint256 marketing1 = marketing / 2;
        uint256 marketing2 = marketing - marketing1;

        (success,) = address(_storage.marketingWallet1).call{value: marketing1}("");

        if(success) {
            emit SendToMarketing1(tokenAmount, marketing1);
        }

        (success,) = address(_storage.marketingWallet2).call{value: marketing2}("");

        if(success) {
            emit SendToMarketing2(tokenAmount, marketing2);
        }

        if(mystery > 0 && address(_storage.mysteryContract) != address(0)) {
            (success,) = address(_storage.mysteryContract).call{value: mystery, gas: 50000}("");

            if(success) {
                emit SendToMystery(tokenAmount, mystery);
            }
        }
    }
}