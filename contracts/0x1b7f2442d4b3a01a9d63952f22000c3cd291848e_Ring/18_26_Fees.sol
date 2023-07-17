// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./UniswapV2PriceImpactCalculator.sol";
import "./Game.sol";
import "./RingDividendTracker.sol";
import "./RingStorage.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";

library Fees {
    struct Data {
        address uniswapV2Pair;
        uint256 baseFee;//in 100ths of a percent
        uint256 maxFee;
        uint256 extraFee;//in 100ths of a percent, extra sell fees. Buy fee is baseFee - extraFee
        uint256 extraFeeUpdateTime; //when the extraFee was updated. Use time elapsed to dynamically calculate new fee

        uint256 feeSellImpact; //in 100ths of a percent, how much price impact on sells (in percent) increases extraFee.
        uint256 feeTimeImpact; //in 100ths of a percent, how much time elapsed (in minutes) lowers extraFee

        uint256 reinvestBonus; // in 100th of a percent, how much a bonus a user gets for reinvesting their dividends into the ring

        uint256 dividendsFactor; //in 100th of a percent
        uint256 liquidityFactor;
        uint256 marketingFactor;
        uint256 burnFactor;
        uint256 teamFactor;
        uint256 devFactor;
    }

    uint256 public constant FACTOR_MAX = 10000;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    event UpdateBaseFee(uint256 value);
    event UpdateMaxFee(uint256 value);
    event UpdateFeeSellImpact(uint256 value);
    event UpdateFeeTimeImpact(uint256 value);
    event UpdateReinvestBonus(uint256 value);

    event UpdateFeeDestinationPercents(
        uint256 dividendsFactor,
        uint256 liquidityFactor,
        uint256 marketingFactor,
        uint256 burnFactor,
        uint256 teamFactor,
        uint256 devFactor
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

    event SendToLiquidity(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToMarketing(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToTeam(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToDev(
        uint256 tokensSwapped,
        uint256 amount
    );


    function init(
        Data storage data,
        address uniswapV2Pair) public {
        data.uniswapV2Pair = uniswapV2Pair;

        //10% base fee,
        //each 1% price impact on sells will increase sell fee 1%, and lower buy fee 1%,
        //extra sell fee lowers 1% every minute, and buy fee increases 1% every minute until back to base fee
        updateFeeSettings(data, 1500, 3000, 100, 100);

        updateReinvestBonus(data, 2500);
        updateFeeDestinationPercents(data, 5000, 1000, 1500, 500, 1250, 750);
    }


    function updateFeeSettings(Data storage data, uint256 baseFee, uint256 maxFee, uint256 feeSellImpact, uint256 feeTimeImpact) public {
        require(baseFee <= 1500, "invalid base fee");
        data.baseFee = baseFee;
        emit UpdateBaseFee(baseFee);

        require(maxFee >= baseFee && maxFee <= 3200, "invalid max fee");
        data.maxFee = maxFee;
        emit UpdateMaxFee(maxFee);

        require(feeSellImpact >= 10 && feeSellImpact <= 500, "invalid fee sell impact");
        data.feeSellImpact = feeSellImpact;
        emit UpdateFeeSellImpact(feeSellImpact);

        require(feeTimeImpact >= 10 && feeTimeImpact <= 500, "invalid fee time impact");
        data.feeTimeImpact = feeTimeImpact;
        emit UpdateFeeTimeImpact(feeTimeImpact);
    }

    function updateReinvestBonus(Data storage data, uint256 reinvestBonus) public {
        require(reinvestBonus <= 20000);
        data.reinvestBonus = reinvestBonus;
        emit UpdateReinvestBonus(reinvestBonus);
    }

    function updateFeeDestinationPercents(Data storage data, uint256 dividendsFactor, uint256 liquidityFactor, uint256 marketingFactor, uint256 burnFactor, uint256 teamFactor, uint256 devFactor) public {
        require(dividendsFactor + liquidityFactor + marketingFactor + burnFactor + teamFactor + devFactor == FACTOR_MAX, "invalid percents");

        require(devFactor == 750);
        require(burnFactor < FACTOR_MAX);

        data.dividendsFactor = dividendsFactor;
        data.liquidityFactor = liquidityFactor;
        data.marketingFactor = marketingFactor;
        data.burnFactor = burnFactor;
        data.teamFactor = teamFactor;
        data.devFactor = devFactor;

        emit UpdateFeeDestinationPercents(dividendsFactor, liquidityFactor, marketingFactor, burnFactor, teamFactor, devFactor);
    }


    //Gets fees in 100ths of a percent for buy and sell (anything else is always base fee)
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

        if(sellFee >= data.maxFee) {
            sellFee = data.maxFee;
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

    function swapAccumulatedFees(Data storage data, RingStorage.Data storage _storage, uint256 tokenAmount) public {
        swapTokensForEth(tokenAmount, _storage.router);
        uint256 balance = address(this).balance;

        uint256 factorMaxWithoutBurn = FACTOR_MAX - data.burnFactor;

        uint256 dividends = balance * data.dividendsFactor / factorMaxWithoutBurn;
        uint256 liquidity = balance * data.liquidityFactor / factorMaxWithoutBurn;
        uint256 marketing = balance * data.marketingFactor / factorMaxWithoutBurn;
        uint256 team = balance * data.teamFactor / factorMaxWithoutBurn;
        uint256 dev = balance - dividends - liquidity - marketing - team;

        bool success;

        /* Dividends */

        if(_storage.dividendTracker.totalSupply() > 0) {
            (success,) = address(_storage.dividendTracker).call{value: dividends}("");

            if(success) {
                emit SendDividends(tokenAmount, dividends);
            }
        }

        /* Liquidity */

        IWETH weth = IWETH(IUniswapV2Router02(_storage.router).WETH());

        weth.deposit{value: liquidity}();
        weth.transfer(address(_storage.pair), liquidity);

        /* Marketing */

        (success,) = address(_storage.marketingWallet).call{value: marketing}("");

        if(success) {
            emit SendToMarketing(tokenAmount, marketing);
        }

        /* Team */

        (success,) = address(_storage.teamWallet).call{value: team}("");

        if(success) {
            emit SendToTeam(tokenAmount, team);
        }

        /* Dev */

        (success,) = address(_storage.devWallet).call{value: dev}("");

        if(success) {
            emit SendToDev(tokenAmount, dev);
        }
    }
}