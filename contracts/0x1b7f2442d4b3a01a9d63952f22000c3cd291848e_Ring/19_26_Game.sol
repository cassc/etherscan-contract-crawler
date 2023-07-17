// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./TokenPriceCalculator.sol";

library Game {
    struct Data {
        uint256 biggestBuyerRewardFactor;
        uint256 lastBuyerRewardFactor;
        uint256 gameMinimumBuy;
        uint256 gameLength;
        uint256 gameTimeIncrease;
        uint256 gameNumber;
        uint256 gameEndTime;
        mapping(uint256 => address) biggestBuyerAccount;
        mapping(uint256 => uint256) biggestBuyerAmount;
        mapping(uint256 => uint256) biggestBuyerPaid;
        mapping(uint256 => address) lastBuyerAccount;
        mapping(uint256 => uint256) lastBuyerPaid;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event UpdateBiggestBuyerRewordFactor(uint256 value);
    event UpdateLastBuyerRewordFactor(uint256 value);
    event UpdateGameMinimumBuy(uint256 value);
    event UpdateGameLength(uint256 value);
    event UpdateGameTimeIncrease(uint256 value);

    event BiggestBuyerPayout(uint256 gameNumber, address indexed account, uint256 value);
    event LastBuyerPayout(uint256 gameNumber, address indexed account, uint256 value);

    function init(Data storage data) public {
        updateGameRewardFactors(data, 250, 250);

        updateGameParams(data, 100, 3600, 15);
    }

    function updateGameRewardFactors(Data storage data, uint256 biggestBuyerRewardFactor, uint256 lastBuyerRewardFactor) public {
        require(biggestBuyerRewardFactor <= 1000, "invalid biggest buyer reward percent"); //max 10%
        data.biggestBuyerRewardFactor = biggestBuyerRewardFactor;
        emit UpdateBiggestBuyerRewordFactor(biggestBuyerRewardFactor);

        require(lastBuyerRewardFactor <= 1000, "invalid last buyer reward percent"); //max 10%
        data.lastBuyerRewardFactor = lastBuyerRewardFactor;
        emit UpdateLastBuyerRewordFactor(lastBuyerRewardFactor);
    }


    function updateGameParams(Data storage data, uint256 gameMinimumBuy, uint256 gameLength, uint256 gameTimeIncrease) public {
        data.gameMinimumBuy = gameMinimumBuy;
        emit UpdateGameMinimumBuy(gameMinimumBuy);

        require(gameLength >= 30 && gameLength <= 1 weeks);
        data.gameLength = gameLength;
        emit UpdateGameLength(gameLength);

        require(gameTimeIncrease >= 1 && gameTimeIncrease <= 1 hours);
        data.gameTimeIncrease = gameTimeIncrease;
        emit UpdateGameTimeIncrease(gameTimeIncrease);
    }

    function start(Data storage data) public {
        data.gameEndTime = block.timestamp + data.gameLength;
    }

    function handleBuy(Data storage data, address account, uint256 amount, IERC20 dividendTracker, address pairAddress) public {
        if(data.gameEndTime == 0) {
            return;
        }

        if(dividendTracker.balanceOf(account) == 0) {
            return;
        }

        if(amount > data.biggestBuyerAmount[data.gameNumber]) {
            data.biggestBuyerAmount[data.gameNumber] = amount;
            data.biggestBuyerAccount[data.gameNumber] = account;
        }

        //compare to USDC price of tokens
        if(data.gameMinimumBuy <= 10000) {
            uint256 tokenPrice = TokenPriceCalculator.calculateTokenPriceInUSDC(address(this), pairAddress);

            uint256 divisor;

            if(block.chainid == 56) {
                divisor = 1e18;
            }
            else {
                divisor = 1e6;
            }

            uint256 amountInUSDCFullDollars = amount * tokenPrice / 1e18 / divisor;

            if(amountInUSDCFullDollars >= data.gameMinimumBuy) {
                data.lastBuyerAccount[data.gameNumber] = account;
                data.gameEndTime += data.gameTimeIncrease;
                if(data.gameEndTime > block.timestamp + data.gameLength) {
                    data.gameEndTime = block.timestamp + data.gameLength;
                }
            }
        }
        //use number of tokens
        else {
            if(amount >= data.gameMinimumBuy) {
                data.lastBuyerAccount[data.gameNumber] = account;
                data.gameEndTime += data.gameTimeIncrease;
                if(data.gameEndTime > block.timestamp + data.gameLength) {
                    data.gameEndTime = block.timestamp + data.gameLength;
                }
            }
        }
    }

    function calculateBiggestBuyerReward(Data storage data, uint256 liquidityTokenBalance) public view returns (uint256) {
        return liquidityTokenBalance * data.biggestBuyerRewardFactor / FACTOR_MAX;
    }

    function calculateLastBuyerReward(Data storage data, uint256 liquidityTokenBalance) public view returns (uint256) {
        return liquidityTokenBalance * data.lastBuyerRewardFactor / FACTOR_MAX;
    }

    function handleGame(Data storage data, uint256 liquidityTokenBalance) public returns (address, uint256, address, uint256) {
        if(data.gameEndTime == 0) {
            return (address(0), 0, address(0), 0);
        }

        if(block.timestamp <= data.gameEndTime) {
            return (address(0), 0, address(0), 0);
        }

        uint256 gameNumber = data.gameNumber;

        /*Biggest*/
        address biggestBuyer = data.biggestBuyerAccount[gameNumber];

        uint256 amountWonBiggestBuyer = calculateBiggestBuyerReward(data, liquidityTokenBalance);

        data.biggestBuyerPaid[gameNumber] = amountWonBiggestBuyer;

        emit BiggestBuyerPayout(gameNumber, biggestBuyer, amountWonBiggestBuyer);

        /*Last*/

        address lastBuyer = data.lastBuyerAccount[gameNumber];

        uint256 amountWonLastBuyer = calculateLastBuyerReward(data, liquidityTokenBalance);

        data.lastBuyerPaid[gameNumber] = amountWonLastBuyer;

        emit LastBuyerPayout(gameNumber, lastBuyer, amountWonLastBuyer);

        data.gameEndTime = block.timestamp + data.gameLength;
        data.gameNumber++;

        return (biggestBuyer, amountWonBiggestBuyer, lastBuyer, amountWonLastBuyer);
    }

    function getBiggestBuyer(Data storage data, uint256 gameNumber) public view returns (address, uint256, uint256, address, uint256) {
        return (
            data.biggestBuyerAccount[gameNumber],
            data.biggestBuyerAmount[gameNumber],
            data.biggestBuyerPaid[gameNumber],
            data.lastBuyerAccount[gameNumber],
            data.lastBuyerPaid[gameNumber]
        );
    }
}