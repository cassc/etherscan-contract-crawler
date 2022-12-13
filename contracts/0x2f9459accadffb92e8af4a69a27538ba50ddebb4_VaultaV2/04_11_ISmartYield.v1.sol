// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;
pragma abicoder v2;

interface ISmartYield {
    function underlying() external view returns (address);

    function bondProvider() external view returns (address);

    function addLiquidity(uint256 tokenAmount_) external;

    function removeLiquidity(uint256 tokenAmount_) external;

    function provideRealizedYield(address bond, uint256 tokenAmount_) external;

    function buyBond(address bond_, uint256 tokenAmount_) external;

    function redeemBond(address bond_, uint256 tokenAmount_) external;

    function rolloverBond(address bond_, uint256 tokenAmount_) external;

    function withdraw(address bond_, uint256 tokenAmount_) external;

    function liquidateDebt(uint256 debtId) external;

    function repay(uint256 debtId) external;

    function borrow(
        address bond,
        uint256 bondAmount,
        address borrowAsset,
        uint256 borrowAmount
    ) external;
}