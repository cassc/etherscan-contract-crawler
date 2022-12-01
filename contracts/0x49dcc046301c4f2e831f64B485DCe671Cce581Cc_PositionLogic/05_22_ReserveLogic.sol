// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IReinvestment.sol";
import "../../interfaces/IUserData.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "../math/InterestUtils.sol";
import "./ValidationLogic.sol";
import "../storage/LedgerStorage.sol";

library ReserveLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUtils for uint256;

    uint256 public constant VERSION = 1;

    /**
     * @dev The reserve supplies
     */
    function getReserveSupplies(
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 unit = LedgerStorage.getAssetStorage().assetConfigs[reserve.asset].decimals;
        uint256 currAvailableSupply;

        if (reserve.ext.reinvestment == address(0)) {
            currAvailableSupply += reserve.liquidSupply;
        } else {
            currAvailableSupply += IReinvestment(reserve.ext.reinvestment).totalSupply();
        }

        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        uint256 currLockedReserveSupplyRay = reserve.scaledUtilizedSupplyRay.rayMul(nextReserveIndexRay);

        uint256 currProtocolUtilizedSupplyRay = reserve.scaledUtilizedSupplyRay.rayMul(nextProtocolIndexRay);

        uint256 currReserveSupply = currAvailableSupply + currLockedReserveSupplyRay.rayToUnit(unit);

        uint256 currUtilizedSupplyRay = currLockedReserveSupplyRay + currProtocolUtilizedSupplyRay;

        uint256 currTotalSupplyRay = currAvailableSupply.unitToRay(unit) + currUtilizedSupplyRay;

        return (
        currAvailableSupply,
        currReserveSupply,
        currProtocolUtilizedSupplyRay.rayToUnit(unit),
        currTotalSupplyRay.rayToUnit(unit),
        currUtilizedSupplyRay.rayToUnit(unit)
        );
    }

    /**
     * Get normalized debt
     * @return the normalized debt. expressed in ray
     **/
    function getReserveIndexes(
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256, uint256, uint256) {
        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        return (
        nextReserveIndexRay,
        nextProtocolIndexRay,
        nextProtocolIndexRay + nextReserveIndexRay
        );
    }

    function updateIndex(
        DataTypes.ReserveData storage reserve
    ) internal {
        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        reserve.reserveIndexRay = nextReserveIndexRay;
        reserve.protocolIndexRay = nextProtocolIndexRay;

        reserve.lastUpdatedTimestamp = block.timestamp;
    }

    function postUpdateReserveData(DataTypes.ReserveData storage reserve) internal {
        uint256 decimals = LedgerStorage.getAssetStorage().assetConfigs[reserve.asset].decimals;

        (,,,uint256 currTotalSupply, uint256 currUtilizedSupply) = getReserveSupplies(reserve);

        reserve.utilizationPercentageRay = currTotalSupply > 0 ? currUtilizedSupply.unitToRay(decimals).rayDiv(
            currTotalSupply.unitToRay(decimals)
        ) : 0;
    }

    function calculateIndexes(
        DataTypes.ReserveData memory reserve,
        uint256 blockTimestamp
    ) private pure returns (uint256, uint256) {
        if (reserve.utilizationPercentageRay == 0) {
            return (
            reserve.reserveIndexRay,
            reserve.protocolIndexRay
            );
        }

        uint256 currBorrowIndexRay = reserve.reserveIndexRay + reserve.protocolIndexRay;

        uint256 interestRateRay = getInterestRate(
            reserve.utilizationPercentageRay,
            uint256(reserve.configuration.protocolRateMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.utilizationBaseRateMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.kinkMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.multiplierAnnualGwei).unitToRay(9),
            uint256(reserve.configuration.jumpMultiplierAnnualGwei).unitToRay(9)
        );

        if (interestRateRay == 0) {
            return (
            reserve.reserveIndexRay,
            reserve.protocolIndexRay
            );
        }

        uint256 cumulatedInterestIndexRay = InterestUtils.getCompoundedInterest(
            interestRateRay, reserve.lastUpdatedTimestamp, blockTimestamp
        );

        uint256 growthIndexRay = currBorrowIndexRay.rayMul(cumulatedInterestIndexRay) - currBorrowIndexRay;

        uint256 protocolInterestRatioRay = uint256(reserve.configuration.protocolRateMantissaGwei).unitToRay(9).rayDiv(interestRateRay);

        uint256 nextProtocolIndexRay = reserve.protocolIndexRay + growthIndexRay.rayMul(protocolInterestRatioRay);

        uint256 nextReserveIndexRay = reserve.reserveIndexRay + growthIndexRay.rayMul(MathUtils.RAY - protocolInterestRatioRay);

        return (nextReserveIndexRay, nextProtocolIndexRay);
    }

    /**
    * @notice Get the interest rate: `rate + utilizationBaseRate + protocolRate`
    * @param utilizationPercentageRay scaledTotalSupplyRay
    * @param protocolRateMantissaRay protocolRateMantissaRay
    * @param utilizationBaseRateMantissaRay utilizationBaseRateMantissaRay
    * @param kinkMantissaRay kinkMantissaRay
    * @param multiplierAnnualRay multiplierAnnualRay
    * @param jumpMultiplierAnnualRay jumpMultiplierAnnualRay
    **/
    function getInterestRate(
        uint256 utilizationPercentageRay,
        uint256 protocolRateMantissaRay,
        uint256 utilizationBaseRateMantissaRay,
        uint256 kinkMantissaRay,
        uint256 multiplierAnnualRay,
        uint256 jumpMultiplierAnnualRay
    ) private pure returns (uint256) {
        uint256 rateRay;

        if (utilizationPercentageRay <= kinkMantissaRay) {
            rateRay = utilizationPercentageRay.rayMul(multiplierAnnualRay);
        } else {
            uint256 normalRateRay = kinkMantissaRay.rayMul(multiplierAnnualRay);
            uint256 excessUtilRay = utilizationPercentageRay - kinkMantissaRay;
            rateRay = excessUtilRay.rayMul(jumpMultiplierAnnualRay) + normalRateRay;
        }

        return rateRay + utilizationBaseRateMantissaRay + protocolRateMantissaRay;
    }

    function cache(
        DataTypes.ReserveData storage reserve
    ) internal view returns (
        DataTypes.ReserveDataCache memory
    ) {
        DataTypes.ReserveDataCache memory reserveCache;

        reserveCache.asset = reserve.asset;
        reserveCache.reinvestment = reserve.ext.reinvestment;
        reserveCache.longReinvestment = reserve.ext.longReinvestment;

        // if the action involves mint/burn of debt, the cache needs to be updated
        reserveCache.currReserveIndexRay = reserve.reserveIndexRay;
        reserveCache.currProtocolIndexRay = reserve.protocolIndexRay;
        reserveCache.currBorrowIndexRay = reserveCache.currReserveIndexRay + reserveCache.currProtocolIndexRay;

        return reserveCache;
    }
}