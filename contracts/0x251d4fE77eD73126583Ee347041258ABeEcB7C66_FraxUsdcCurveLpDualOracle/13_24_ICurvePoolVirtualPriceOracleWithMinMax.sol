// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ICurvePoolVirtualPriceOracleWithMinMax is IERC165 {
    event SetMaximumCurvePoolVirtualPrice(uint256 oldMaximum, uint256 newMaximum);
    event SetMinimumCurvePoolVirtualPrice(uint256 oldMinimum, uint256 newMinimum);

    function CURVE_POOL_VIRTUAL_PRICE_ADDRESS() external view returns (address);

    function CURVE_POOL_VIRTUAL_PRICE_PRECISION() external view returns (uint256);

    function getCurvePoolVirtualPrice() external view returns (uint256 _virtualPrice);

    function maximumCurvePoolVirtualPrice() external view returns (uint256);

    function minimumCurvePoolVirtualPrice() external view returns (uint256);

    function setMaximumCurvePoolVirtualPrice(uint256 _newMaximum) external;

    function setMinimumCurvePoolVirtualPrice(uint256 _newMinimum) external;
}