// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Fees.sol";
import "./Game.sol";
import "./Referrals.sol";
import "./Transfers.sol";
import "./RingDividendTracker.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./Transfers.sol";
import "./LiquidityBurnCalculator.sol";
import "./IUniswapV2Factory.sol";
import "./TokenPriceCalculator.sol";

library RingStorage {
    using Transfers for Transfers.Data;
    using Game for Game.Data;
    using Referrals for Referrals.Data;
    using Fees for Fees.Data;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event LiquidityBurn(
        uint256 amount
    );

    struct Data {
        Fees.Data fees;
        Game.Data game;
        Referrals.Data referrals;
        Transfers.Data transfers;
        IUniswapV2Router02 router;
        IUniswapV2Pair pair;
        RingDividendTracker dividendTracker;
        address marketingWallet;
        address teamWallet;
        address devWallet;

        uint256 swapTokensAtAmount;
        uint256 swapTokensMaxAmount;

        uint256 startTime;

        bool swapping;
        bool zapping;

        mapping (address => bool) isExcludedFromFees;

        mapping (address => bool) privateSaleAccount;
        mapping (address => uint256) privateSaleTokensMoved;

        uint256 liquidityTokensAvailableToBurn;
        uint256 liquidityBurnTime;
    }

    function init(RingStorage.Data storage data, address owner) public {
        if(block.chainid == 56) {
            data.router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        }
        else {
            data.router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }

        data.pair = IUniswapV2Pair(
          IUniswapV2Factory(data.router.factory()
        ).createPair(address(this), data.router.WETH()));

        IUniswapV2Pair(data.pair).approve(address(data.router), type(uint).max);

        setSwapTokensParams(data, 200 * (10**18), 1000 * (10**18));

        data.fees.init(address(data.pair));
        data.game.init();
        data.referrals.init();
        data.transfers.init(address(data.router), address(data.pair));
        data.dividendTracker = new RingDividendTracker(payable(address(this)));
        setupDividendTracker(data, owner);

        data.marketingWallet = 0xCFf117048F428D958d65c8FEB400a7c94be854BF;
        data.teamWallet = 0xA04875753cA65F0C1A690657466c353c8FEC872F;
        data.devWallet = 0x818C3BBA79411df1b4547cbe95a65bdedF73C3F7;


        excludeFromFees(data, owner, true);
        excludeFromFees(data, address(this), true);
        excludeFromFees(data, address(data.router), true);
        excludeFromFees(data, address(data.dividendTracker), true);
        excludeFromFees(data, Fees.deadAddress, true);
        excludeFromFees(data, data.marketingWallet, true);
        excludeFromFees(data, data.devWallet, true);
    }

    function getData(RingStorage.Data storage data, address account, uint256 liquidityTokenBalance) external view returns (uint256[] memory dividendInfo, uint256 referralCode, int256 buyFee, uint256 sellFee, address biggestBuyerCurrentGame, uint256 biggestBuyerAmountCurrentGame, uint256 biggestBuyerRewardCurrentGame, address lastBuyerCurrentGame, uint256 lastBuyerRewardCurrentGame, uint256 gameEndTime, uint256 blockTimestamp) {
        dividendInfo = data.dividendTracker.getDividendInfo(account);

        referralCode = data.referrals.getReferralCode(account);

        (buyFee,
        sellFee) = data.fees.getCurrentFees();

        uint256 gameNumber = data.game.gameNumber;

        (biggestBuyerCurrentGame, biggestBuyerAmountCurrentGame,,lastBuyerCurrentGame,) = data.game.getBiggestBuyer(gameNumber);

        biggestBuyerRewardCurrentGame = data.game.calculateBiggestBuyerReward(liquidityTokenBalance);

        lastBuyerRewardCurrentGame = data.game.calculateLastBuyerReward(liquidityTokenBalance);

        gameEndTime = data.game.gameEndTime;

        blockTimestamp = block.timestamp;
    }

    function setupDividendTracker(RingStorage.Data storage data, address owner) public {
        data.dividendTracker.excludeFromDividends(address(data.dividendTracker));
        data.dividendTracker.excludeFromDividends(address(this));
        data.dividendTracker.excludeFromDividends(owner);
        data.dividendTracker.excludeFromDividends(Fees.deadAddress);
        data.dividendTracker.excludeFromDividends(address(data.router));
        data.dividendTracker.excludeFromDividends(address(data.pair));
    }

    function excludeFromFees(RingStorage.Data storage data, address account, bool excluded) public {
        data.isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setSwapTokensParams(RingStorage.Data storage data, uint256 atAmount, uint256 maxAmount) public {
        require(atAmount < 1000 * (10**18));
        data.swapTokensAtAmount = atAmount;

        require(maxAmount < 10000 * (10**18));
        data.swapTokensMaxAmount = maxAmount;
    }

    function startGame(RingStorage.Data storage data) public {
        data.startTime = block.timestamp;
        data.game.start();
    }

    function getPrivateSaleMovableTokens(RingStorage.Data storage data, address account) public view returns (uint256) {
        if(data.startTime == 0) {
            return 0;
        }

        uint256 daysSinceLaunch;

        daysSinceLaunch = (block.timestamp - data.startTime) / 1 days;

        uint256 totalTokensAllowedToMove = daysSinceLaunch * 1000 * 10**18;
        uint256 tokensMoved = data.privateSaleTokensMoved[account];

        if(totalTokensAllowedToMove <= tokensMoved) {
            return 0;
        }

        return totalTokensAllowedToMove - tokensMoved;
    }

    function burnLiquidityTokens(RingStorage.Data storage data, uint256 liquidityTokenBalance) public returns(uint256) {
        uint256 burnAmount = LiquidityBurnCalculator.calculateBurn(
            liquidityTokenBalance,
            data.liquidityTokensAvailableToBurn,
            data.liquidityBurnTime);

        if(burnAmount == 0) {
            return 0;
        }

        data.liquidityBurnTime = block.timestamp;
        data.liquidityTokensAvailableToBurn -= burnAmount;

        emit LiquidityBurn(burnAmount);

        return burnAmount;
    }

    function handleNewBalanceForReferrals(RingStorage.Data storage data, address account, uint256 balance) public {
        if(data.isExcludedFromFees[account]) {
            return;
        }

        if(account == address(data.pair)) {
            return;
        }

        data.referrals.handleNewBalance(account, balance);
    }
}