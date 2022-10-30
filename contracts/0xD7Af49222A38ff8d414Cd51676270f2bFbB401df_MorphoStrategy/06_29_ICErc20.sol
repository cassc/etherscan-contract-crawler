// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface ICErc20 {
    function balanceOf(address owner) external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 tokenAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function underlying() external view returns (address);
}