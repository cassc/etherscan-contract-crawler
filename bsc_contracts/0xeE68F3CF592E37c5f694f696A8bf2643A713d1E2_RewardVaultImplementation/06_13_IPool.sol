// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IDToken.sol";

interface IPool {

    function liquidity() external view returns (int256);

    struct LpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }

    function lpInfos(uint256) external view returns (LpInfo memory);

    function lToken() external view returns (IDToken);

    function tokenB0() external view returns (address);

    function vTokenB0() external view returns (address);

    function marketB0() external view returns (address);

}