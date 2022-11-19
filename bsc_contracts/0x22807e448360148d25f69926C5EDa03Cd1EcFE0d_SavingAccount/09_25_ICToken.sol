// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface ICToken {
    function supplyRatePerBlock() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemAmount) external returns (uint256);

    function exchangeRateStore() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);
}