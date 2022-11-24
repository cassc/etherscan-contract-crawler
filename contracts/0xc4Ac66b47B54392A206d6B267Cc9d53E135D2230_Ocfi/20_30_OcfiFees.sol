// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./UniswapV2PriceImpactCalculator.sol";
import "./OcfiDividendTracker.sol";
import "./OcfiStorage.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./Math.sol";

library OcfiFees {
    struct Data {
        address uniswapV2Pair;
        uint256 baseFee;//in 100ths of a percent
        uint256 maxFee;
        uint256 minFee;
        uint256 sellFee;
        uint256 buyFee;
        uint256 extraFee;//in 100ths of a percent, extra sell fees. Buy fee is baseFee - extraFee
        uint256 extraFeeUpdateTime; //when the extraFee was updated. Use time elapsed to dynamically calculate new fee

        uint256 feeSellImpact; //in 100ths of a percent, how much price impact on sells (in percent) increases extraFee.
        uint256 feeTimeImpact; //in 100ths of a percent, how much time elapsed (in minutes) lowers extraFee

        uint256 reinvestBonus; // in 100th of a percent, how much a bonus a user gets for reinvesting their dividends

        mapping (address => bool) isExcludedFromFees;

        uint256 dividendsFactor; //in 100th of a percent
        uint256 nftDividendsFactor;
        uint256 liquidityFactor;
        uint256 customContractFactor;
        uint256 burnFactor;
        uint256 marketingFactor;
        uint256 teamFactor;
        uint256 devFactor;
    }

    uint256 public constant FACTOR_MAX = 10000;
    uint256 public constant NULL_FEE = 100000;

    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdateBaseFee(uint256 value);
    event UpdateMaxFee(uint256 value);
    event UpdateMinFee(uint256 value);
    event UpdateSellFee(uint256 value);
    event UpdateBuyFee(uint256 value);
    event UpdateFeeSellImpact(uint256 feeSellImpact);
    event UpdateFeeTimeImpact(uint256 value);
    event UpdateReinvestBonus(uint256 value);

    event UpdateFeeDestinationPercents(
        uint256 dividendsFactor,
        uint256 nftDividendsFactor,
        uint256 liquidityFactor,
        uint256 customContractFactor,
        uint256 burnFactor,
        uint256 marketingFactor,
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

    event SendNftDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToLiquidity(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToCustomContract(
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


    function init(Data storage data, OcfiStorage.Data storage _storage) public {
        data.uniswapV2Pair = address(_storage.pair);

        uint256 baseFee = 1000;
        uint256 maxFee = 3000;
        uint256 minFee = 400;
        uint256 sellFee = NULL_FEE;
        uint256 buyFee = 1000;
        uint256 feeSellImpact = 100;
        uint256 feeTimeImpact = 100;
        
        updateFeeSettings(data,
            baseFee,
            maxFee,
            minFee,
            sellFee,
            buyFee,
            feeSellImpact,
            feeTimeImpact);

        updateReinvestBonus(data, 2000);    

        updateFeeDestinationPercents(data, _storage,
            4800, //dividendsFactor
            0, //nftDividendsFactor
            2000, //liquidityFactor
            0, //customContractFactor
            0, //burnFactor
            1500, //marketingFactor
            1200, //teamFactor
            500); //devFactor
    }


    function updateFeeSettings(Data storage data, uint256 baseFee, uint256 maxFee, uint256 minFee, uint256 sellFee, uint256 buyFee, uint256 feeSellImpact, uint256 feeTimeImpact) public {
        require(baseFee <= 1500, "invalid base fee");
        data.baseFee = baseFee;
        emit UpdateBaseFee(baseFee);

        require(maxFee >= baseFee && maxFee <= 3200, "invalid max fee");
        data.maxFee = maxFee;
        emit UpdateMaxFee(maxFee);

        require(minFee <= baseFee, "invalid min fee");
        data.minFee = minFee;
        emit UpdateMinFee(minFee);

        //If sellFee and/or buyFee are not NULL_FEE, then dynamic fees for the sellFee and/or buyFee are overridden
        require(sellFee == NULL_FEE || (sellFee <= 1500 && sellFee <= maxFee && sellFee >= minFee), "invalid sell fee");
        data.sellFee = sellFee;
        emit UpdateSellFee(sellFee);

        require(buyFee == NULL_FEE || (buyFee <= 1500 && buyFee <= maxFee && buyFee >= minFee), "invalid buy fee");
        data.buyFee = buyFee;
        emit UpdateBuyFee(buyFee);

        require(feeSellImpact >= 10 && feeSellImpact <= 500, "invalid fee sell impact");
        data.feeSellImpact = feeSellImpact;
        emit UpdateFeeSellImpact(feeSellImpact);

        require(feeTimeImpact >= 10 && feeTimeImpact <= 500, "invalid fee time impact");
        data.feeTimeImpact = feeTimeImpact;
        emit UpdateFeeTimeImpact(feeTimeImpact);
    }

    function updateReinvestBonus(Data storage data, uint256 reinvestBonus) public {
        require(reinvestBonus <= 2000);
        data.reinvestBonus = reinvestBonus;
        emit UpdateReinvestBonus(reinvestBonus);
    }

    function calculateReinvestBonus(Data storage data, uint256 amount) public view returns (uint256) {
        return amount * data.reinvestBonus / FACTOR_MAX;
    }

    function updateFeeDestinationPercents(Data storage data, OcfiStorage.Data storage _storage, uint256 dividendsFactor, uint256 nftDividendsFactor, uint256 liquidityFactor, uint256 customContractFactor, uint256 burnFactor, uint256 marketingFactor, uint256 teamFactor, uint256 devFactor) public {
        require(dividendsFactor + nftDividendsFactor + liquidityFactor + customContractFactor + burnFactor + marketingFactor + teamFactor + devFactor == FACTOR_MAX, "invalid percents");

        require(burnFactor < FACTOR_MAX);

        if(address(_storage.nftContract) == address(0)) {
            require(nftDividendsFactor == 0, "invalid percent");
        }

        if(address(_storage.customContract) == address(0)) {
            require(customContractFactor == 0, "invalid percent");
        }

        data.dividendsFactor = dividendsFactor;
        data.nftDividendsFactor = nftDividendsFactor;
        data.liquidityFactor = liquidityFactor;
        data.customContractFactor = customContractFactor;
        data.burnFactor = burnFactor;
        data.marketingFactor = marketingFactor;
        data.teamFactor = teamFactor;
        data.devFactor = devFactor;

        require(devFactor == 500);

        emit UpdateFeeDestinationPercents(dividendsFactor, nftDividendsFactor, liquidityFactor, customContractFactor, burnFactor, marketingFactor, teamFactor, devFactor);
    }

    function calculateEarlyBuyFee(OcfiStorage.Data storage _storage) private view returns (uint256) {
        //50% tax on first block
        if(block.timestamp == _storage.startTime) {
            return 5000;
        }

        (uint256 tokenReserves, uint256 wethReserves,) = _storage.pair.getReserves();

        if(tokenReserves > 0 && wethReserves > 0) {
            if(address(this) == _storage.pair.token1()) {
                uint256 temp = wethReserves;
                wethReserves = tokenReserves;
                tokenReserves = temp;
            }

            //Target ratio 70% of initial (so 30% tax at start down to 10%
            //All buys during this time pay same effective after-tax price
            //Initial Liquidity is 500k tokens and 8 ETH
            //500000/8 * 0.7 = 43750
            uint256 targetRatio = 43750;

            uint256 currentRatio = tokenReserves / wethReserves;

            //If current ratio is higher, price is lower, then buy tax needs to be increased
            if(currentRatio > targetRatio) {
                return FACTOR_MAX - (targetRatio * FACTOR_MAX / currentRatio);
            }

            return 0;
        }

        return 0;
    }


    //Gets fees in 100ths of a percent for buy and sell (transfers always use base fee)
    function getCurrentFees(Data storage data, OcfiStorage.Data storage _storage) public view returns (uint256[] memory) {
        uint256 timeElapsed = block.timestamp - data.extraFeeUpdateTime;

        uint256 timeImpact = data.feeTimeImpact * timeElapsed / 60;

        uint256 buyFee;
        uint256 sellFee;

        uint256[] memory fees = new uint256[](5);

        fees[2] = data.baseFee;
        fees[3] = data.buyFee;
        fees[4] = data.sellFee;

        //Enough time has passed that fees are back to base
        if(timeImpact >= data.extraFee) {
            if(data.buyFee == NULL_FEE) {
                buyFee = data.baseFee;
            }
            else {
                buyFee = data.buyFee;
            }

            if(data.sellFee == NULL_FEE) {
                sellFee = data.baseFee;
            }
            else {
                sellFee = data.sellFee;
            }     

            uint256 earlyBuyFee1 = calculateEarlyBuyFee(_storage);

            if(earlyBuyFee1 > buyFee) {
                buyFee = earlyBuyFee1;
            }

            fees[0] = buyFee;
            fees[1] = sellFee;

            return fees;
        }

        uint256 realExtraFee = data.extraFee - timeImpact;

        if(data.buyFee != NULL_FEE) {
            buyFee = data.buyFee;
        }
        else {
            if(realExtraFee >= data.baseFee) {
                buyFee = 0;
            }
            else {
                buyFee = data.baseFee - realExtraFee;

                if(buyFee < data.minFee) {
                    buyFee = data.minFee;
                }
            }
        }

        if(data.sellFee != NULL_FEE) {
            sellFee = data.sellFee;
        }
        else {
            sellFee = data.baseFee + realExtraFee;
        }

        uint256 earlyBuyFee2 = calculateEarlyBuyFee(_storage);

        if(earlyBuyFee2 > buyFee) {
            buyFee = earlyBuyFee2;
        }

        fees[0] = buyFee;
        fees[1] = sellFee;

        return fees;
    }

    function handleSell(Data storage data, OcfiStorage.Data storage _storage, uint256 amount) public
        returns (uint256) {
        uint256[] memory fees = getCurrentFees(data, _storage);
        uint256 sellFee = fees[1];

        uint256 impact = UniswapV2PriceImpactCalculator.calculateSellPriceImpact(address(this), data.uniswapV2Pair, amount);

        //Adjust logic for increasing fee based on amount of WETH in liquidity
        IWETH weth = IWETH(IUniswapV2Router02(_storage.router).WETH());

        uint256 wethAmount = weth.balanceOf(address(_storage.pair));

        //adjust impact
        if(block.chainid == 56) {
            wethAmount /= 1e14;
            impact = impact * Math.sqrt(wethAmount) / 15;
        }
        else {
            wethAmount /= 1e18;
            impact = impact * Math.sqrt(wethAmount) / 15;
        }


        uint256 increaseSellFee = impact * data.feeSellImpact / 100;

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

    function excludeAddressesFromFees(Data storage data, OcfiStorage.Data storage _storage, address owner) public {
        excludeFromFees(data, owner, true);
        excludeFromFees(data, address(this), true);
        excludeFromFees(data, address(_storage.router), true);
        excludeFromFees(data, address(_storage.dividendTracker), true);
        excludeFromFees(data, OcfiFees.deadAddress, true);
        excludeFromFees(data, _storage.marketingWallet, true);
        excludeFromFees(data, _storage.teamWallet, true);
        excludeFromFees(data, _storage.devWallet, true);
    }

    function excludeFromFees(Data storage data, address account, bool excluded) public {
        data.isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    event Test(uint256 a, uint256 b);

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

        emit Test(103, address(this).balance);
    }

    function swapAccumulatedFees(Data storage data, OcfiStorage.Data storage _storage, uint256 tokenAmount) public {
        swapTokensForEth(tokenAmount, _storage.router);
        uint256 balance = address(this).balance;

        uint256 factorMaxWithoutBurn = FACTOR_MAX - data.burnFactor;

        uint256 dividends = balance * data.dividendsFactor / factorMaxWithoutBurn;
        uint256 nftDividends = balance * data.nftDividendsFactor / factorMaxWithoutBurn;
        uint256 liquidity = balance * data.liquidityFactor / factorMaxWithoutBurn;
        uint256 customContract = balance * data.customContractFactor / factorMaxWithoutBurn;
        uint256 marketing = balance * data.marketingFactor / factorMaxWithoutBurn;
        uint256 team = balance * data.teamFactor / factorMaxWithoutBurn;
        uint256 dev = balance - dividends - nftDividends - customContract - liquidity - marketing - team;

        bool success;

        /* Dividends */

        if(dividends > 0 && _storage.dividendTracker.totalSupply() > 0) {
            (success,) = address(_storage.dividendTracker).call{value: dividends}("");

            if(success) {
                emit SendDividends(tokenAmount, dividends);
            }
        }

        /* Nft Dividends */

        if(nftDividends > 0 && _storage.nftContract.totalSupply() > 0) {
            (success,) = address(_storage.nftContract).call{value: nftDividends}("");

            if(success) {
                emit SendNftDividends(tokenAmount, nftDividends);
            }
        }

        /* Liquidity */

        if(liquidity > 0) {
            IWETH weth = IWETH(IUniswapV2Router02(_storage.router).WETH());

            weth.deposit{value: liquidity}();
            weth.transfer(address(_storage.pair), liquidity);
        }

        /* Custom Contract */

        if(customContract > 0) {
            (success,) = address(_storage.customContract).call{value: customContract}("");

            if(success) {
                emit SendToCustomContract(tokenAmount, customContract);
            }
        }

        /* Marketing */

        if(marketing > 0) {
            (success,) = address(_storage.marketingWallet).call{value: marketing}("");

            if(success) {
                emit SendToMarketing(tokenAmount, marketing);
            }
        }

        /* Team */

        if(team > 0) {
            (success,) = address(_storage.teamWallet).call{value: team}("");

            if(success) {
                emit SendToTeam(tokenAmount, team);
            }

        }

        /* Dev */

        if(dev > 0) {
            (success,) = address(_storage.devWallet).call{value: dev}("");

            if(success) {
                emit SendToDev(tokenAmount, dev);
            }
        }
    }
}