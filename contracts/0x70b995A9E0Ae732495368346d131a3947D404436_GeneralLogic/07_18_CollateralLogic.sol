// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../math/MathUtils.sol";
import "../../types/DataTypes.sol";

library CollateralLogic {
    using MathUtils for uint256;

    function getCollateralSupply(
        DataTypes.CollateralData memory collateral
    ) internal view returns (uint256){
        return collateral.reinvestment == address(0)
        ? collateral.liquidSupply
        : IReinvestment(collateral.reinvestment).totalSupply();
    }
}