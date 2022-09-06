// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IOpenSkyMoneyMarket.sol';
import '../interfaces/IOpenSkyDataProvider.sol';
import '../interfaces/IOpenSkyPool.sol';
import '../interfaces/IOpenSkyOToken.sol';
import '../interfaces/IOpenSkyLoan.sol';
import '../interfaces/IOpenSkyInterestRateStrategy.sol';

import '../libraries/math/WadRayMath.sol';
import '../libraries/math/MathUtils.sol';
import '../libraries/types/DataTypes.sol';

contract OpenSkyDataProvider is IOpenSkyDataProvider {
    using WadRayMath for uint256;

    IOpenSkySettings public immutable SETTINGS;

    constructor(IOpenSkySettings settings) {
        SETTINGS = settings;
    }

    function getReserveData(uint256 reserveId) external view override returns (ReserveData memory) {
        IOpenSkyPool pool = IOpenSkyPool(SETTINGS.poolAddress());
        DataTypes.ReserveData memory reserve = pool.getReserveData(reserveId);
        IERC20 oToken = IERC20(reserve.oTokenAddress);
        return
            ReserveData({
                reserveId: reserveId,
                underlyingAsset: reserve.underlyingAsset,
                oTokenAddress: reserve.oTokenAddress,
                TVL: pool.getTVL(reserveId),
                totalDeposits: oToken.totalSupply(),
                totalBorrowsBalance: pool.getTotalBorrowBalance(reserveId),
                supplyRate: getSupplyRate(reserveId),
                borrowRate: getBorrowRate(reserveId, 0, 0, 0, 0),
                availableLiquidity: pool.getAvailableLiquidity(reserveId)
            });
    }

    function getTVL(uint256 reserveId) external view override returns (uint256) {
        return IOpenSkyPool(SETTINGS.poolAddress()).getTVL(reserveId);
    }

    function getTotalBorrowBalance(uint256 reserveId) external view override returns (uint256) {
        return IOpenSkyPool(SETTINGS.poolAddress()).getTotalBorrowBalance(reserveId);
    }

    function getAvailableLiquidity(uint256 reserveId) external view override returns (uint256) {
        return IOpenSkyPool(SETTINGS.poolAddress()).getAvailableLiquidity(reserveId);
    }

    function getSupplyRate(uint256 reserveId) public view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);

        uint256 tvl = IOpenSkyOToken(reserve.oTokenAddress).principleTotalSupply();

        (, uint256 utilizationRate) = MathUtils.calculateLoanSupplyRate(
            tvl,
            reserve.totalBorrows,
            getBorrowRate(reserveId, 0, 0, 0, 0)
        );

        return
            getLoanSupplyRate(reserveId) + ((WadRayMath.ray() - utilizationRate).rayMul(getMoneyMarketSupplyRateInstant(reserveId)));
    }

    function getLoanSupplyRate(uint256 reserveId) public view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);
        uint256 tvl = IOpenSkyOToken(reserve.oTokenAddress).principleTotalSupply();
        (uint256 loanSupplyRate, ) = MathUtils.calculateLoanSupplyRate(
            tvl,
            reserve.totalBorrows,
            getBorrowRate(reserveId, 0, 0, 0, 0)
        );
        return loanSupplyRate;
    }

    function getMoneyMarketSupplyRateInstant(uint256 reserveId) public view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);
        if (reserve.isMoneyMarketOn) {
            return IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getSupplyRate(reserve.underlyingAsset);
        } else {
            return 0;
        }
    }

    function getBorrowRate(
        uint256 reserveId,
        uint256 liquidityAmountToAdd,
        uint256 liquidityAmountToRemove,
        uint256 borrowAmountToAdd,
        uint256 borrowAmountToRemove
    ) public view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);
        return
            IOpenSkyInterestRateStrategy(reserve.interestModelAddress).getBorrowRate(
                reserveId,
                IOpenSkyOToken(reserve.oTokenAddress).totalSupply() + liquidityAmountToAdd - liquidityAmountToRemove,
                reserve.totalBorrows + borrowAmountToAdd - borrowAmountToRemove
            );
    }

    function getSupplyBalance(uint256 reserveId, address account) external view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IOpenSkyPool(SETTINGS.poolAddress()).getReserveData(reserveId);
        return IERC20(reserve.oTokenAddress).balanceOf(account);
    }

    function getLoanData(uint256 loanId) external view override returns (LoanData memory) {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loan = loanNFT.getLoanData(loanId);
        return
            LoanData({
                loanId: loanId,
                totalBorrows: loan.amount,
                borrowBalance: loanNFT.getBorrowBalance(loanId),
                borrowBegin: loan.borrowBegin,
                borrowDuration: loan.borrowDuration,
                borrowOverdueTime: loan.borrowOverdueTime,
                liquidatableTime: loan.liquidatableTime,
                extendableTime: loan.extendableTime,
                borrowRate: loan.borrowRate,
                interestPerSecond: loan.interestPerSecond,
                penalty: loanNFT.getPenalty(loanId),
                status: loan.status
            });
    }

    function getLoansByUser(address account) external view override returns (uint256[] memory) {
        IERC721Enumerable loanNFT = IERC721Enumerable(SETTINGS.loanAddress());
        uint256 amount = loanNFT.balanceOf(account);
        uint256[] memory ids = new uint256[](amount > 0 ? amount : 0);
        for (uint256 i = 0; i < amount; ++i) {
            ids[i] = loanNFT.tokenOfOwnerByIndex(account, i);
        }
        return ids;
    }
}