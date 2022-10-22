// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITreasury {
    function getTeamReleased() external view returns (uint256);

    function getLiquidityReleased() external view returns (uint256);

    function getFoundationReleased() external view returns (uint256);

    function getMarketingReleased() external view returns (uint256);

    function getTokenSaleReleased() external view returns (uint256);

    function releaseTokenTeam(
        address token,
        address to,
        uint8 phase
    ) external;

    function releaseTokenLiquidity(
        address token,
        address to,
        uint256 amount
    ) external;

    function releaseTokenFoundation(
        address token,
        address to,
        uint256 amount
    ) external;

    function releaseTokenMarketing(
        address token,
        address to,
        uint256 amount
    ) external;

    function releaseTokenTokenSale(
        address token,
        address to,
        uint256 amount
    ) external;
}