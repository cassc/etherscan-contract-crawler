// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

library ScalingUtils {
    using MathUpgradeable for uint256;

    uint256 internal constant ONE = 1e18;

    /**
     * @notice Scale value by decimals
     * @param sourceValue Value of the source to scale
     * @param sourceDecimals Decimals of the source
     * @param targetDecimals Decimals of the target
     * @return Value of the target
     */
    function scaleByDecimals(uint256 sourceValue, uint8 sourceDecimals, uint8 targetDecimals)
        internal
        pure
        returns (uint256)
    {
        if (targetDecimals >= sourceDecimals) {
            return sourceValue * (10 ** (targetDecimals - sourceDecimals));
        } else {
            return sourceValue / (10 ** (sourceDecimals - targetDecimals));
        }
    }

    /**
     * @notice Scale value by decimals
     * @param sourceValue Value of the source to scale
     * @param sourceDecimals Decimals of the source
     * @param targetDecimals Decimals of the target
     * @param rounding Rounding mode that is `Up` or `Down`
     * @return Value of the target
     */
    function scaleByDecimals(
        uint256 sourceValue,
        uint8 sourceDecimals,
        uint8 targetDecimals,
        MathUpgradeable.Rounding rounding
    ) internal pure returns (uint256) {
        return scaleByBases(sourceValue, 10 ** sourceDecimals, 10 ** targetDecimals, rounding);
    }

    /**
     * @notice Scale value by bases
     * @param sourceValue Value of the source to scale
     * @param sourceBase Base of the source, e.g., 1e18
     * @param targetBase Base of the target, e.g., 1e6
     * @return Value of the target
     */
    function scaleByBases(uint256 sourceValue, uint256 sourceBase, uint256 targetBase)
        internal
        pure
        returns (uint256)
    {
        if (targetBase >= sourceBase) {
            return sourceValue * (targetBase / sourceBase);
        } else {
            return sourceValue / (sourceBase / targetBase);
        }
    }

    /**
     * @notice Scale value by bases
     * @param sourceValue Value of the source to scale
     * @param sourceBase Base of the source, e.g., 1e18
     * @param targetBase Base of the target, e.g., 1e6
     * @param rounding Rounding mode that is `Up` or `Down`
     * @return Value of the target
     */
    function scaleByBases(
        uint256 sourceValue,
        uint256 sourceBase,
        uint256 targetBase,
        MathUpgradeable.Rounding rounding
    ) internal pure returns (uint256) {
        return sourceValue.mulDiv(targetBase, sourceBase, rounding);
    }
}