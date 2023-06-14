// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ICurvePoolEmaPriceOracleWithMinMax is IERC165 {
    event SetMaximumCurvePoolEma(uint256 oldMaximum, uint256 newMaximum);
    event SetMinimumCurvePoolEma(uint256 oldMinimum, uint256 newMinimum);

    function CURVE_POOL_EMA_PRICE_ORACLE() external view returns (address);

    function CURVE_POOL_EMA_PRICE_ORACLE_PRECISION() external view returns (uint256);

    function getCurvePoolToken1EmaPrice() external view returns (uint256 _emaPrice);

    function maximumCurvePoolEma() external view returns (uint256);

    function minimumCurvePoolEma() external view returns (uint256);

    function setMaximumCurvePoolEma(uint256 _maximumPrice) external;

    function setMinimumCurvePoolEma(uint256 _minimumPrice) external;
}