// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./common/DelegateInterface.sol";
import "./common/Adminable.sol";
import "./common/ReentrancyGuard.sol";
import "./IOPBorrowing.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/DexData.sol";
import "./libraries/Utils.sol";

import "./OPBorrowingLib.sol";

contract OPBorrowing is DelegateInterface, Adminable, ReentrancyGuard, IOPBorrowing, OPBorrowingStorage {
    using TransferHelper for IERC20;
    using DexData for bytes;

    constructor(
        OpenLevInterface _openLev,
        ControllerInterface _controller,
        DexAggregatorInterface _dexAgg,
        XOLEInterface _xOLE,
        address _wETH
    ) OPBorrowingStorage(_openLev, _controller, _dexAgg, _xOLE, _wETH) {}

    /// @notice Initialize contract only by admin
    /// @dev This function is supposed to call multiple times
    /// @param _marketDefConf The market default config after the new market was created
    /// @param _liquidationConf The liquidation config
    function initialize(MarketConf memory _marketDefConf, LiquidationConf memory _liquidationConf) external override onlyAdmin {
        marketDefConf = _marketDefConf;
        liquidationConf = _liquidationConf;
    }

    /// @notice Create new market only by controller contract
    /// @param marketId The new market id
    /// @param pool0 The pool0 address
    /// @param pool1 The pool1 address
    /// @param dexData The dex data (0x03 means PANCAKE)
    function addMarket(uint16 marketId, LPoolInterface pool0, LPoolInterface pool1, bytes memory dexData) external override {
        require(msg.sender == address(controller), "NCN");
        addMarketInternal(marketId, pool0, pool1, pool0.underlying(), pool1.underlying(), dexData);
    }

    struct BorrowVars {
        address collateralToken; // the collateral token address
        address borrowToken; // the borrow token address
        LPoolInterface borrowPool; // the borrow pool address
        uint collateralTotalReserve; // the collateral token balance of this contract
        uint collateralTotalShare; // the collateral token total share
        uint borrowTotalReserve; // the borrow token balance of this contract
        uint borrowTotalShare; // the borrow token total share
    }

    /// @notice Sender collateralize token to borrow this market another token
    /// @dev This function will collect borrow fees and check the borrowing amount is healthy
    /// @param marketId The market id
    /// @param collateralIndex The collateral index (false means token0)
    /// @param collateral The collateral token amount
    /// @param borrowing The borrow token amount to borrow
    function borrow(uint16 marketId, bool collateralIndex, uint collateral, uint borrowing) external payable override nonReentrant {
        address borrower = msg.sender;
        controller.collBorrowAllowed(marketId, borrower, collateralIndex);

        BorrowVars memory borrowVars = toBorrowVars(marketId, collateralIndex);

        MarketConf storage marketConf = marketsConf[marketId];
        collateral = OPBorrowingLib.transferIn(borrower, IERC20(borrowVars.collateralToken), wETH, collateral);

        if (collateral > 0) {
            // amount to share
            collateral = OPBorrowingLib.amountToShare(collateral, borrowVars.collateralTotalShare, borrowVars.collateralTotalReserve);
            increaseCollateralShare(borrower, marketId, collateralIndex, borrowVars.collateralToken, collateral);
        }
        require(collateral > 0 || borrowing > 0, "CB0");
        uint fees;
        if (borrowing > 0) {
            // check minimal borrowing > absolute value 0.0001
            {
                uint decimals = OPBorrowingLib.decimals(borrowVars.borrowToken);
                uint minimalBorrows = decimals > 4 ? 10 ** (decimals - 4) : 1;
                require(borrowing > minimalBorrows, "BTS");
            }

            uint borrowed = OPBorrowingLib.borrowBehalf(borrowVars.borrowPool, borrowVars.borrowToken, borrower, borrowing);
            // check pool's liquidity * maxLiquidityRatio >= totalBorrow
            {
                uint borrowTWALiquidity = collateralIndex ? twaLiquidity[marketId].token0Liq : twaLiquidity[marketId].token1Liq;
                bytes memory dexData = OPBorrowingLib.uint32ToBytes(markets[marketId].dex);
                uint borrowLiquidity = dexAgg.getToken0Liquidity(borrowVars.borrowToken, borrowVars.collateralToken, dexData);
                uint minLiquidity = Utils.minOf(borrowTWALiquidity, borrowLiquidity);
                require((minLiquidity * marketConf.maxLiquidityRatio) / RATIO_DENOMINATOR >= borrowVars.borrowPool.totalBorrows(), "BGL");
                // check healthy
                uint totalCollateral = activeCollaterals[borrower][marketId][collateralIndex];
                uint accountTotalBorrowed = OPBorrowingLib.borrowStored(borrowVars.borrowPool, borrower);
                require(
                    checkHealthy(
                        marketId,
                        OPBorrowingLib.shareToAmount(
                            totalCollateral,
                            totalShares[borrowVars.collateralToken],
                            OPBorrowingLib.balanceOf(IERC20(borrowVars.collateralToken))
                        ),
                        accountTotalBorrowed,
                        borrowVars.collateralToken,
                        borrowVars.borrowToken
                    ),
                    "BNH"
                );
            }
            // collect borrow fees
            fees = collectBorrowFee(
                marketId,
                collateralIndex,
                borrowing,
                borrowVars.borrowToken,
                borrowVars.borrowPool,
                borrowVars.borrowTotalReserve,
                borrowVars.borrowTotalShare
            );
            // transfer out borrowed - fees
            OPBorrowingLib.doTransferOut(borrower, IERC20(borrowVars.borrowToken), wETH, borrowed - fees);
        }

        emit Borrow(borrower, marketId, collateralIndex, collateral, borrowing, fees);
    }

    /// @notice Sender repay borrowings and redeem collateral token
    /// @dev This function will redeem all collateral token if borrowing is 0
    ///  and redeem partial collateral token if the isRedeem=true and borrowing is healthy
    /// @param marketId The market id
    /// @param collateralIndex The collateral index (false means token0)
    /// @param repayAmount The amount to repay
    /// @param isRedeem If equal true, will redeem (repayAmount/totalBorrowing)*collateralAmount token
    function repay(uint16 marketId, bool collateralIndex, uint repayAmount, bool isRedeem) external payable override nonReentrant returns (uint redeemShare) {
        address borrower = msg.sender;
        controller.collRepayAllowed(marketId);
        // check collateral
        uint collateral = activeCollaterals[borrower][marketId][collateralIndex];
        checkCollateral(collateral);

        BorrowVars memory borrowVars = toBorrowVars(marketId, collateralIndex);

        uint borrowPrior = OPBorrowingLib.borrowCurrent(borrowVars.borrowPool, borrower);
        require(borrowPrior > 0, "BL0");
        if (repayAmount == type(uint256).max) {
            repayAmount = borrowPrior;
        }
        repayAmount = OPBorrowingLib.transferIn(borrower, IERC20(borrowVars.borrowToken), wETH, repayAmount);
        require(repayAmount > 0, "RL0");
        // repay
        OPBorrowingLib.repay(borrowVars.borrowPool, borrower, repayAmount);
        uint borrowAfterRepay = OPBorrowingLib.borrowStored(borrowVars.borrowPool, borrower);
        // in the tax token case, should get actual repayment amount
        repayAmount = borrowPrior - borrowAfterRepay;
        // borrowing is 0, so return all collateral
        if (borrowAfterRepay == 0) {
            redeemShare = collateral;
            decreaseCollateralShare(borrower, marketId, collateralIndex, borrowVars.collateralToken, redeemShare);
            OPBorrowingLib.doTransferOut(
                borrower,
                IERC20(borrowVars.collateralToken),
                wETH,
                OPBorrowingLib.shareToAmount(redeemShare, borrowVars.collateralTotalShare, borrowVars.collateralTotalReserve)
            );
        }
        // redeem collateral= borrower.collateral * repayRatio
        else if (isRedeem) {
            uint repayRatio = (repayAmount * RATIO_DENOMINATOR) / borrowPrior;
            redeemShare = (collateral * repayRatio) / RATIO_DENOMINATOR;
            if (redeemShare > 0) {
                redeemInternal(borrower, marketId, collateralIndex, redeemShare, borrowAfterRepay, borrowVars);
            }
        }
        emit Repay(borrower, marketId, collateralIndex, repayAmount, redeemShare);
    }

    /// @notice Sender redeem collateral token
    /// @dev This function will check borrowing is healthy after collateral redeemed
    /// @param marketId The market id
    /// @param collateral The collateral index (false means token0)
    /// @param collateral The collateral share to redeem
    function redeem(uint16 marketId, bool collateralIndex, uint collateral) external override nonReentrant {
        address borrower = msg.sender;
        controller.collRedeemAllowed(marketId);

        BorrowVars memory borrowVars = toBorrowVars(marketId, collateralIndex);

        uint borrowPrior = OPBorrowingLib.borrowCurrent(borrowVars.borrowPool, borrower);

        redeemInternal(borrower, marketId, collateralIndex, collateral, borrowPrior, borrowVars);

        emit Redeem(borrower, marketId, collateralIndex, collateral);
    }

    struct LiquidateVars {
        uint collateralAmount; // the amount of collateral token
        uint borrowing; // the borrowing amount
        uint liquidationAmount; // the amount of collateral token to liquidate
        uint liquidationShare; // the share of collateral token to liquidate
        uint liquidationFees; // the liquidation fees
        bool isPartialLiquidate; // liquidate partial or fully
        bytes dexData; // the dex data
        bool buySuccess; // Whether or not buy enough borrowing token to repay
        uint repayAmount; // the repay amount
        uint buyAmount; // buy borrowing token amount
        uint price0; // the price of token0/token1
        uint collateralToBorrower; // the collateral amount back to the borrower
        uint outstandingAmount; // the outstanding amount
    }

    /// @notice Liquidate borrower collateral
    /// @dev This function will call by any users and bots.
    /// will trigger in the borrower collateral * ratio < borrowing
    /// @param marketId The market id
    /// @param collateralIndex The collateral index (false means token0)
    /// @param borrower The borrower address
    function liquidate(uint16 marketId, bool collateralIndex, address borrower) external override nonReentrant {
        controller.collLiquidateAllowed(marketId);
        // check collateral
        uint collateral = activeCollaterals[borrower][marketId][collateralIndex];
        checkCollateral(collateral);

        BorrowVars memory borrowVars = toBorrowVars(marketId, collateralIndex);
        LiquidateVars memory liquidateVars;
        liquidateVars.borrowing = OPBorrowingLib.borrowCurrent(borrowVars.borrowPool, borrower);
        liquidateVars.collateralAmount = OPBorrowingLib.shareToAmount(collateral, borrowVars.collateralTotalShare, borrowVars.collateralTotalReserve);

        // check liquidable
        require(checkLiquidable(marketId, liquidateVars.collateralAmount, liquidateVars.borrowing, borrowVars.collateralToken, borrowVars.borrowToken), "BIH");
        // check msg.sender xOLE
        require(xOLE.balanceOf(msg.sender) >= liquidationConf.liquidatorXOLEHeld, "XNE");
        // compute liquidation collateral
        MarketConf storage marketConf = marketsConf[marketId];
        liquidateVars.liquidationAmount = liquidateVars.collateralAmount;
        liquidateVars.liquidationShare = collateral;
        liquidateVars.dexData = OPBorrowingLib.uint32ToBytes(markets[marketId].dex);
        // liquidationAmount = collateralAmount/2 when the collateralAmount >= liquidity * liquidateMaxLiquidityRatio
        {
            uint collateralLiquidity = dexAgg.getToken0Liquidity(borrowVars.collateralToken, borrowVars.borrowToken, liquidateVars.dexData);
            uint maxLiquidity = (collateralLiquidity * marketConf.liquidateMaxLiquidityRatio) / RATIO_DENOMINATOR;
            if (liquidateVars.liquidationAmount >= maxLiquidity) {
                liquidateVars.liquidationShare = liquidateVars.liquidationShare / 2;
                liquidateVars.liquidationAmount = OPBorrowingLib.shareToAmount(
                    liquidateVars.liquidationShare,
                    borrowVars.collateralTotalShare,
                    borrowVars.collateralTotalReserve
                );
                liquidateVars.isPartialLiquidate = true;
            }
        }
        (liquidateVars.price0, ) = dexAgg.getPrice(markets[marketId].token0, markets[marketId].token1, liquidateVars.dexData);
        // compute sell collateral amount, borrowings + liquidationFees + tax
        {
            uint24 borrowTokenTransTax = openLev.taxes(marketId, borrowVars.borrowToken, 0);
            uint24 borrowTokenBuyTax = openLev.taxes(marketId, borrowVars.borrowToken, 2);
            uint24 collateralSellTax = openLev.taxes(marketId, borrowVars.collateralToken, 1);

            liquidateVars.repayAmount = Utils.toAmountBeforeTax(liquidateVars.borrowing, borrowTokenTransTax);
            liquidateVars.liquidationFees = (liquidateVars.borrowing * marketConf.liquidateFeesRatio) / RATIO_DENOMINATOR;
            OPBorrowingLib.safeApprove(IERC20(borrowVars.collateralToken), address(dexAgg), liquidateVars.liquidationAmount);
            (liquidateVars.buySuccess, ) = address(dexAgg).call(
                abi.encodeWithSelector(
                    dexAgg.buy.selector,
                    borrowVars.borrowToken,
                    borrowVars.collateralToken,
                    borrowTokenBuyTax,
                    collateralSellTax,
                    liquidateVars.repayAmount + liquidateVars.liquidationFees,
                    liquidateVars.liquidationAmount,
                    liquidateVars.dexData
                )
            );
        }
        /*
         * if buySuccess==true, repay all debts and returns collateral
         */
        if (liquidateVars.buySuccess) {
            uint sellAmount = borrowVars.collateralTotalReserve - OPBorrowingLib.balanceOf(IERC20(borrowVars.collateralToken));
            liquidateVars.collateralToBorrower = liquidateVars.collateralAmount - sellAmount;
            liquidateVars.buyAmount = OPBorrowingLib.balanceOf(IERC20(borrowVars.borrowToken)) - borrowVars.borrowTotalReserve;
            require(liquidateVars.buyAmount >= liquidateVars.repayAmount, "BLR");
            OPBorrowingLib.repay(borrowVars.borrowPool, borrower, liquidateVars.repayAmount);
            // check borrowing is 0
            require(OPBorrowingLib.borrowStored(borrowVars.borrowPool, borrower) == 0, "BG0");
            unchecked {
                liquidateVars.liquidationFees = liquidateVars.buyAmount - liquidateVars.repayAmount;
            }
            liquidateVars.liquidationShare = collateral;
        }
        /*
         * if buySuccess==false and isPartialLiquidate==true, sell liquidation amount and repay with buyAmount
         * if buySuccess==false and isPartialLiquidate==false, sell liquidation amount and repay with buyAmount + insurance
         */
        else {
            liquidateVars.buyAmount = dexAgg.sell(
                borrowVars.borrowToken,
                borrowVars.collateralToken,
                liquidateVars.liquidationAmount,
                0,
                liquidateVars.dexData
            );
            liquidateVars.liquidationFees = (liquidateVars.buyAmount * marketConf.liquidateFeesRatio) / RATIO_DENOMINATOR;
            if (liquidateVars.isPartialLiquidate) {
                liquidateVars.repayAmount = liquidateVars.buyAmount - liquidateVars.liquidationFees;
                OPBorrowingLib.repay(borrowVars.borrowPool, borrower, liquidateVars.repayAmount);
                require(OPBorrowingLib.borrowStored(borrowVars.borrowPool, borrower) != 0, "BE0");
            } else {
                uint insuranceShare = collateralIndex ? insurances[marketId].insurance0 : insurances[marketId].insurance1;
                uint insuranceAmount = OPBorrowingLib.shareToAmount(insuranceShare, borrowVars.borrowTotalShare, borrowVars.borrowTotalReserve);
                uint diffRepayAmount = liquidateVars.repayAmount + liquidateVars.liquidationFees - liquidateVars.buyAmount;
                uint insuranceDecrease;
                if (insuranceAmount >= diffRepayAmount) {
                    OPBorrowingLib.repay(borrowVars.borrowPool, borrower, liquidateVars.repayAmount);
                    insuranceDecrease = OPBorrowingLib.amountToShare(diffRepayAmount, borrowVars.borrowTotalShare, borrowVars.borrowTotalReserve);
                } else {
                    liquidateVars.repayAmount = liquidateVars.buyAmount + insuranceAmount - liquidateVars.liquidationFees;
                    borrowVars.borrowPool.repayBorrowEndByOpenLev(borrower, liquidateVars.repayAmount);
                    liquidateVars.outstandingAmount = diffRepayAmount - insuranceAmount;
                    insuranceDecrease = insuranceShare;
                }
                decreaseInsuranceShare(insurances[marketId], !collateralIndex, borrowVars.borrowToken, insuranceDecrease);
            }
        }
        // collect liquidation fees
        collectLiquidationFee(
            marketId,
            collateralIndex,
            liquidateVars.liquidationFees,
            borrowVars.borrowToken,
            borrowVars.borrowPool,
            borrowVars.borrowTotalReserve,
            borrowVars.borrowTotalShare
        );
        decreaseCollateralShare(borrower, marketId, collateralIndex, borrowVars.collateralToken, liquidateVars.liquidationShare);
        // transfer remaining collateral to borrower
        if (liquidateVars.collateralToBorrower > 0) {
            OPBorrowingLib.doTransferOut(borrower, IERC20(borrowVars.collateralToken), wETH, liquidateVars.collateralToBorrower);
        }
        emit Liquidate(
            borrower,
            marketId,
            collateralIndex,
            msg.sender,
            liquidateVars.liquidationShare,
            liquidateVars.repayAmount,
            liquidateVars.outstandingAmount,
            liquidateVars.liquidationFees,
            liquidateVars.price0
        );
    }

    /// @notice Calculate borrower collateral ratio for display purposes
    /// @dev This function will compute borrower collateral ratio=collateral * ratio / borrowing (10000 means 100%).
    /// If the collateral ratio is less than 10000, it can be liquidated
    /// @param marketId The market id
    /// @param collateralIndex The collateral index (false means token0)
    /// @param borrower The borrower address
    /// @return scaled by RATIO_DENOMINATOR
    function collateralRatio(uint16 marketId, bool collateralIndex, address borrower) external view override returns (uint) {
        BorrowVars memory borrowVars = toBorrowVars(marketId, collateralIndex);
        uint borrowed = borrowVars.borrowPool.borrowBalanceCurrent(borrower);
        uint collateral = activeCollaterals[borrower][marketId][collateralIndex];
        if (borrowed == 0 || collateral == 0) {
            return 100 * RATIO_DENOMINATOR;
        }
        uint collateralAmount = OPBorrowingLib.shareToAmount(collateral, borrowVars.collateralTotalShare, borrowVars.collateralTotalReserve);
        MarketConf storage marketConf = marketsConf[marketId];
        bytes memory dexData = OPBorrowingLib.uint32ToBytes(markets[marketId].dex);
        (uint price, uint8 decimals) = dexAgg.getPrice(borrowVars.collateralToken, borrowVars.borrowToken, dexData);
        return (((collateralAmount * price) / (10 ** uint(decimals))) * marketConf.collateralRatio) / borrowed;
    }

    /*** Admin Functions ***/

    /// @notice Admin migrate markets from openLev contract
    /// @param from The from market id
    /// @param to The to market id
    function migrateOpenLevMarkets(uint16 from, uint16 to) external override onlyAdmin {
        for (uint16 i = from; i <= to; i++) {
            OpenLevInterface.Market memory market = openLev.markets(i);
            addMarketInternal(
                i,
                LPoolInterface(market.pool0),
                LPoolInterface(market.pool1),
                market.token0,
                market.token1,
                OPBorrowingLib.uint32ToBytes(openLev.getMarketSupportDexs(i)[0])
            );
        }
    }

    function setTwaLiquidity(uint16[] calldata marketIds, OPBorrowingStorage.Liquidity[] calldata liquidity) external override onlyAdminOrDeveloper {
        require(marketIds.length == liquidity.length, "IIL");
        for (uint i = 0; i < marketIds.length; i++) {
            uint16 marketId = marketIds[i];
            setTwaLiquidityInternal(marketId, liquidity[i].token0Liq, liquidity[i].token1Liq);
        }
    }

    function setMarketConf(uint16 marketId, OPBorrowingStorage.MarketConf calldata _marketConf) external override onlyAdmin {
        require(_marketConf.insuranceRatio + _marketConf.poolReturnsRatio <= RATIO_DENOMINATOR, "BPI");
        require(_marketConf.liquidatorReturnsRatio + _marketConf.liquidateInsuranceRatio + _marketConf.liquidatePoolReturnsRatio <= RATIO_DENOMINATOR, "LPI");
        require(_marketConf.collateralRatio < RATIO_DENOMINATOR, "CRI");
        require(_marketConf.liquidateFeesRatio < RATIO_DENOMINATOR, "LRI");

        marketsConf[marketId] = _marketConf;
        emit NewMarketConf(
            marketId,
            _marketConf.collateralRatio,
            _marketConf.maxLiquidityRatio,
            _marketConf.borrowFeesRatio,
            _marketConf.insuranceRatio,
            _marketConf.poolReturnsRatio,
            _marketConf.liquidateFeesRatio,
            _marketConf.liquidatorReturnsRatio,
            _marketConf.liquidateInsuranceRatio,
            _marketConf.liquidatePoolReturnsRatio,
            _marketConf.liquidateMaxLiquidityRatio,
            _marketConf.twapDuration
        );
    }

    function setMarketDex(uint16 marketId, uint32 dex) external override onlyAdmin {
        markets[marketId].dex = dex;
    }

    /// @notice Admin move insurance to other address
    /// @param marketId The market id
    /// @param tokenIndex The token index (false means token0)
    /// @param to The address of insurance to transfer
    /// @param moveShare The insurance share to move
    function moveInsurance(uint16 marketId, bool tokenIndex, address to, uint moveShare) external override onlyAdmin {
        address token = !tokenIndex ? markets[marketId].token0 : markets[marketId].token1;
        uint256 totalShare = totalShares[token];
        decreaseInsuranceShare(insurances[marketId], tokenIndex, token, moveShare);
        OPBorrowingLib.safeTransfer(IERC20(token), to, OPBorrowingLib.shareToAmount(moveShare, totalShare, OPBorrowingLib.balanceOf(IERC20(token))));
    }

    function redeemInternal(address borrower, uint16 marketId, bool collateralIndex, uint redeemShare, uint borrowing, BorrowVars memory borrowVars) internal {
        uint collateral = activeCollaterals[borrower][marketId][collateralIndex];
        require(collateral >= redeemShare, "RGC");
        decreaseCollateralShare(borrower, marketId, collateralIndex, borrowVars.collateralToken, redeemShare);
        // redeem
        OPBorrowingLib.doTransferOut(
            borrower,
            IERC20(borrowVars.collateralToken),
            wETH,
            OPBorrowingLib.shareToAmount(redeemShare, borrowVars.collateralTotalShare, borrowVars.collateralTotalReserve)
        );
        // check healthy
        require(
            checkHealthy(
                marketId,
                OPBorrowingLib.shareToAmount(
                    activeCollaterals[borrower][marketId][collateralIndex],
                    totalShares[borrowVars.collateralToken],
                    OPBorrowingLib.balanceOf(IERC20(borrowVars.collateralToken))
                ),
                borrowing,
                borrowVars.collateralToken,
                borrowVars.borrowToken
            ),
            "BNH"
        );
    }

    function increaseCollateralShare(address borrower, uint16 marketId, bool collateralIndex, address token, uint increaseShare) internal {
        activeCollaterals[borrower][marketId][collateralIndex] += increaseShare;
        totalShares[token] += increaseShare;
    }

    function decreaseCollateralShare(address borrower, uint16 marketId, bool collateralIndex, address token, uint decreaseShare) internal {
        activeCollaterals[borrower][marketId][collateralIndex] -= decreaseShare;
        totalShares[token] -= decreaseShare;
    }

    function increaseInsuranceShare(Insurance storage insurance, bool index, address token, uint increaseShare) internal {
        if (!index) {
            insurance.insurance0 += increaseShare;
        } else {
            insurance.insurance1 += increaseShare;
        }
        totalShares[token] += increaseShare;
    }

    function decreaseInsuranceShare(Insurance storage insurance, bool index, address token, uint decreaseShare) internal {
        if (!index) {
            insurance.insurance0 -= decreaseShare;
        } else {
            insurance.insurance1 -= decreaseShare;
        }
        totalShares[token] -= decreaseShare;
    }

    function checkCollateral(uint collateral) internal pure {
        require(collateral > 0, "CE0");
    }

    function collectBorrowFee(
        uint16 marketId,
        bool collateralIndex,
        uint borrowed,
        address borrowToken,
        LPoolInterface borrowPool,
        uint borrowTotalReserve,
        uint borrowTotalShare
    ) internal returns (uint) {
        MarketConf storage marketConf = marketsConf[marketId];
        uint fees = (borrowed * marketConf.borrowFeesRatio) / RATIO_DENOMINATOR;
        if (fees > 0) {
            uint poolReturns = (fees * marketConf.poolReturnsRatio) / RATIO_DENOMINATOR;
            if (poolReturns > 0) {
                OPBorrowingLib.safeTransfer(IERC20(borrowToken), address(borrowPool), poolReturns);
            }
            uint insurance = (fees * marketConf.insuranceRatio) / RATIO_DENOMINATOR;
            if (insurance > 0) {
                uint increaseInsurance = OPBorrowingLib.amountToShare(insurance, borrowTotalShare, borrowTotalReserve);
                increaseInsuranceShare(insurances[marketId], !collateralIndex, borrowToken, increaseInsurance);
            }
            uint xoleAmount = fees - poolReturns - insurance;
            if (xoleAmount > 0) {
                OPBorrowingLib.safeTransfer(IERC20(borrowToken), address(xOLE), xoleAmount);
            }
        }
        return fees;
    }

    function collectLiquidationFee(
        uint16 marketId,
        bool collateralIndex,
        uint liquidationFees,
        address borrowToken,
        LPoolInterface borrowPool,
        uint borrowTotalReserve,
        uint borrowTotalShare
    ) internal returns (bool buyBackSuccess) {
        if (liquidationFees > 0) {
            MarketConf storage marketConf = marketsConf[marketId];
            uint poolReturns = (liquidationFees * marketConf.liquidatePoolReturnsRatio) / RATIO_DENOMINATOR;
            if (poolReturns > 0) {
                OPBorrowingLib.safeTransfer(IERC20(borrowToken), address(borrowPool), poolReturns);
            }
            uint insurance = (liquidationFees * marketConf.liquidateInsuranceRatio) / RATIO_DENOMINATOR;
            if (insurance > 0) {
                uint increaseInsurance = OPBorrowingLib.amountToShare(insurance, borrowTotalShare, borrowTotalReserve);
                increaseInsuranceShare(insurances[marketId], !collateralIndex, borrowToken, increaseInsurance);
            }
            uint liquidatorReturns = (liquidationFees * marketConf.liquidatorReturnsRatio) / RATIO_DENOMINATOR;
            if (liquidatorReturns > 0) {
                OPBorrowingLib.safeTransfer(IERC20(borrowToken), msg.sender, liquidatorReturns);
            }
            uint buyBackAmount = liquidationFees - poolReturns - insurance - liquidatorReturns;
            if (buyBackAmount > 0) {
                OPBorrowingLib.safeApprove(IERC20(borrowToken), address(liquidationConf.buyBack), buyBackAmount);
                (buyBackSuccess, ) = address(liquidationConf.buyBack).call(
                    abi.encodeWithSelector(liquidationConf.buyBack.transferIn.selector, borrowToken, buyBackAmount)
                );
                OPBorrowingLib.safeApprove(IERC20(borrowToken), address(liquidationConf.buyBack), 0);
            }
        }
    }

    /// @notice Check collateral * ratio >= borrowed
    function checkHealthy(uint16 marketId, uint collateral, uint borrowed, address collateralToken, address borrowToken) internal returns (bool) {
        if (borrowed == 0) {
            return true;
        }
        MarketConf storage marketConf = marketsConf[marketId];
        // update price
        uint32 dex = markets[marketId].dex;
        uint collateralPrice;
        uint denominator;
        {
            (uint price, uint cAvgPrice, uint hAvgPrice, uint8 decimals, ) = updatePrices(collateralToken, borrowToken, marketConf.twapDuration, dex);
            collateralPrice = Utils.minOf(Utils.minOf(price, cAvgPrice), hAvgPrice);
            denominator = (10 ** uint(decimals));
        }
        return (((collateral * collateralPrice) / denominator) * marketConf.collateralRatio) / RATIO_DENOMINATOR >= borrowed;
    }

    /// @notice Check collateral * ratio < borrowed
    function checkLiquidable(uint16 marketId, uint collateral, uint borrowed, address collateralToken, address borrowToken) internal returns (bool) {
        if (borrowed == 0) {
            return false;
        }
        MarketConf storage marketConf = marketsConf[marketId];
        // update price
        uint32 dex = markets[marketId].dex;
        uint collateralPrice;
        uint denominator;
        {
            (uint price, uint cAvgPrice, uint hAvgPrice, uint8 decimals, ) = updatePrices(collateralToken, borrowToken, marketConf.twapDuration, dex);
            // avoids flash loan
            if (price < cAvgPrice && price != 0) {
                uint diffPriceRatio = (cAvgPrice * 100) / price;
                require(diffPriceRatio - 100 <= liquidationConf.priceDiffRatio, "MPT");
            }
            collateralPrice = Utils.maxOf(Utils.maxOf(price, cAvgPrice), hAvgPrice);
            denominator = (10 ** uint(decimals));
        }
        return (((collateral * collateralPrice) / denominator) * marketConf.collateralRatio) / RATIO_DENOMINATOR < borrowed;
    }

    function updatePrices(
        address collateralToken,
        address borrowToken,
        uint16 twapDuration,
        uint32 dex
    ) internal returns (uint price, uint cAvgPrice, uint hAvgPrice, uint8 decimals, uint timestamp) {
        bytes memory dexData = OPBorrowingLib.uint32ToBytes(dex);
        if (dexData.isUniV2Class()) {
            dexAgg.updatePriceOracle(collateralToken, borrowToken, twapDuration, dexData);
        }
        (price, cAvgPrice, hAvgPrice, decimals, timestamp) = dexAgg.getPriceCAvgPriceHAvgPrice(collateralToken, borrowToken, twapDuration, dexData);
    }

    function addMarketInternal(uint16 marketId, LPoolInterface pool0, LPoolInterface pool1, address token0, address token1, bytes memory dexData) internal {
        // init market info
        markets[marketId] = Market(pool0, pool1, token0, token1, dexData.toDexDetail());
        // init default config
        marketsConf[marketId] = marketDefConf;
        // init liquidity
        (uint token0Liq, uint token1Liq) = dexAgg.getPairLiquidity(token0, token1, dexData);
        setTwaLiquidityInternal(marketId, token0Liq, token1Liq);
        // approve the max number for pools
        OPBorrowingLib.safeApprove(IERC20(token0), address(pool0), type(uint256).max);
        OPBorrowingLib.safeApprove(IERC20(token1), address(pool1), type(uint256).max);
        emit NewMarket(marketId, pool0, pool1, token0, token1, dexData.toDexDetail(), token0Liq, token1Liq);
    }

    function setTwaLiquidityInternal(uint16 marketId, uint token0Liq, uint token1Liq) internal {
        uint oldToken0Liq = twaLiquidity[marketId].token0Liq;
        uint oldToken1Liq = twaLiquidity[marketId].token1Liq;
        twaLiquidity[marketId] = Liquidity(token0Liq, token1Liq);
        emit NewLiquidity(marketId, oldToken0Liq, oldToken1Liq, token0Liq, token1Liq);
    }

    function toBorrowVars(uint16 marketId, bool collateralIndex) internal view returns (BorrowVars memory) {
        BorrowVars memory borrowVars;
        borrowVars.collateralToken = collateralIndex ? markets[marketId].token1 : markets[marketId].token0;
        borrowVars.borrowToken = collateralIndex ? markets[marketId].token0 : markets[marketId].token1;
        borrowVars.borrowPool = collateralIndex ? markets[marketId].pool0 : markets[marketId].pool1;
        borrowVars.collateralTotalReserve = OPBorrowingLib.balanceOf(IERC20(borrowVars.collateralToken));
        borrowVars.collateralTotalShare = totalShares[borrowVars.collateralToken];
        borrowVars.borrowTotalReserve = OPBorrowingLib.balanceOf(IERC20(borrowVars.borrowToken));
        borrowVars.borrowTotalShare = totalShares[borrowVars.borrowToken];
        return borrowVars;
    }
}