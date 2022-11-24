/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../intf/IDealer.sol";
import "../intf/IPerpetual.sol";
import "../utils/SignedDecimalMath.sol";

contract Perpetual is Ownable, IPerpetual {
    using SignedDecimalMath for int256;

    // ========== storage ==========

    /*
        We use int128 to store paper and reduced credit, 
        so that we could store balance in a single slot.
        This trick can help us saving gas.

        int128 can support size of 1.7E38, which is enough 
        for most transactions. But other than storing paper 
        and reduced credit values, we use int256 to achieve 
        higher accuracy of calculation.

        Normally, paper amount will be a 1e18 based decimal.
    */
    struct balance {
        int128 paper;
        int128 reducedCredit;
    }
    mapping(address => balance) balanceMap;
    int256 fundingRate;

    // ========== events ==========

    event BalanceChange(
        address indexed trader,
        int256 paperChange,
        int256 creditChange
    );

    event UpdateFundingRate(int256 oldFundingRate, int256 newFundingRate);

    // ========== constructor ==========

    constructor(address _owner) Ownable() {
        transferOwnership(_owner);
    }

    // ========== balance related ==========

    /*
        We store "reducedCredit" instead of credit itself.
        So that after funding rate is updated, the credit values will be
        updated without any extra storage write.
        
        credit = (paper * fundingRate) + reducedCredit

        FundingRate here is a little different from what it means at CEX.
        FundingRate is a cumulative value. Its absolute value doesn't mean 
        anything and only the changes (due to funding updates) matter.

        e.g. If the fundingRate increases by 5 at a certain update, 
        then you will receive 5 credit for every paper you long.
        And you will be charged 5 credit for every paper you short.
    */

    /// @inheritdoc IPerpetual
    function balanceOf(address trader)
        external
        view
        returns (int256 paper, int256 credit)
    {
        paper = int256(balanceMap[trader].paper);
        credit =
            paper.decimalMul(fundingRate) +
            int256(balanceMap[trader].reducedCredit);
    }

    function updateFundingRate(int256 newFundingRate) external onlyOwner {
        int256 oldFundingRate = fundingRate;
        fundingRate = newFundingRate;
        emit UpdateFundingRate(oldFundingRate, newFundingRate);
    }

    function getFundingRate() external view returns (int256) {
        return fundingRate;
    }

    // ========== trade ==========

    /// @inheritdoc IPerpetual
    function trade(bytes calldata tradeData) external {
        (
            address[] memory traderList,
            int256[] memory paperChangeList,
            int256[] memory creditChangeList
        ) = IDealer(owner()).approveTrade(msg.sender, tradeData);

        for (uint256 i = 0; i < traderList.length; ) {
            _settle(traderList[i], paperChangeList[i], creditChangeList[i]);
            unchecked {
                ++i;
            }
        }

        require(IDealer(owner()).isAllSafe(traderList), "TRADER_NOT_SAFE");
    }

    // ========== liquidation ==========

    /// @inheritdoc IPerpetual
    function liquidate(
        address liquidatedTrader,
        int256 requestPaper,
        int256 expectCredit
    ) external returns (int256 liqtorPaperChange, int256 liqtorCreditChange) {
        // liqed => liquidated trader, who faces the risk of liquidation.
        // liqtor => liquidator, who takes over the trader's position.
        int256 liqedPaperChange;
        int256 liqedCreditChange;
        (
            liqtorPaperChange,
            liqtorCreditChange,
            liqedPaperChange,
            liqedCreditChange
        ) = IDealer(owner()).requestLiquidation(
            msg.sender,
            liquidatedTrader,
            requestPaper
        );

        // expected price = expectCredit/requestPaper * -1
        // execute price = liqtorCreditChange/liqtorPaperChange * -1
        if (liqtorPaperChange < 0) {
            // open short, execute price >= expected price
            // liqtorCreditChange/liqtorPaperChange * -1 >= expectCredit/requestPaper * -1
            // liqtorCreditChange/liqtorPaperChange <= expectCredit/requestPaper
            // liqtorCreditChange*requestPaper <= expectCredit*liqtorPaperChange
            require(
                liqtorCreditChange * requestPaper <=
                    expectCredit * liqtorPaperChange,
                "LIQUIDATION_PRICE_PROTECTION"
            );
        } else {
            // open long, execute price <= expected price
            // liqtorCreditChange/liqtorPaperChange * -1 <= expectCredit/requestPaper * -1
            // liqtorCreditChange/liqtorPaperChange >= expectCredit/requestPaper
            // liqtorCreditChange*requestPaper >= expectCredit*liqtorPaperChange
            require(
                liqtorCreditChange * requestPaper >=
                    expectCredit * liqtorPaperChange,
                "LIQUIDATION_PRICE_PROTECTION"
            );
        }

        _settle(liquidatedTrader, liqedPaperChange, liqedCreditChange);
        _settle(msg.sender, liqtorPaperChange, liqtorCreditChange);
        require(IDealer(owner()).isSafe(msg.sender), "LIQUIDATOR_NOT_SAFE");
        if (balanceMap[liquidatedTrader].paper == 0) {
            IDealer(owner()).handleBadDebt(liquidatedTrader);
        }
    }

    // ========== settlement ==========

    /*
        Remember the fomula?
        credit = (paper * fundingRate) + reducedCredit

        So we have...
        reducedCredit = credit - (paper * fundingRate)

        When you update the balance, you need to first calculate the credit, 
        and then calculate and store the reducedCredit.
    */

    function _settle(
        address trader,
        int256 paperChange,
        int256 creditChange
    ) internal {
        bool isNewPosition = balanceMap[trader].paper == 0;
        int256 rate = fundingRate; // gas saving
        int256 credit = int256(balanceMap[trader].paper).decimalMul(rate) +
            int256(balanceMap[trader].reducedCredit) +
            creditChange;
        int128 newPaper = balanceMap[trader].paper + int128(paperChange);
        int128 newReducedCredit = int128(
            credit - int256(newPaper).decimalMul(rate)
        );
        balanceMap[trader].paper = newPaper;
        balanceMap[trader].reducedCredit = newReducedCredit;
        emit BalanceChange(trader, paperChange, creditChange);
        if (isNewPosition) {
            IDealer(owner()).openPosition(trader);
        }
        if (balanceMap[trader].paper == 0) {
            // realize PNL
            IDealer(owner()).realizePnl(
                trader,
                balanceMap[trader].reducedCredit
            );
            balanceMap[trader].reducedCredit = 0;
        }
    }
}