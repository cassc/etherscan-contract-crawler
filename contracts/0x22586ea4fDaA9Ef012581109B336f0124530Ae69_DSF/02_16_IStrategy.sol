//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategy {
    enum WithdrawalType { Base, OneCoin }

    function deposit(uint256[3] memory amounts) external returns (uint256);

    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external returns (bool);

    function withdrawAll() external;

    function totalHoldings() external view returns (uint256);

    function claimManagementFees() external returns (uint256);

    function autoCompound() external;

    function calcWithdrawOneCoin(
        uint256 userRatioOfCrvLps,
        uint128 tokenIndex
    ) external view returns(uint256 tokenAmount);

    function calcSharesAmount(
        uint256[3] memory tokenAmounts,
        bool isDeposit
    ) external view returns(uint256 sharesAmount);
}