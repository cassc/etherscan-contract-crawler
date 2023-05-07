//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyAPS {
    function deposit(uint256 amount) external returns (uint256);

    function withdraw(
        address withdrawer,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256 tokenAmount
    ) external returns (bool);

    function withdrawAll() external;

    function totalHoldings() external view returns (uint256);

    function claimManagementFees() external returns (uint256);

    function autoCompound() external;

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps)
        external
        view
        returns (uint256 tokenAmount);

    function calcSharesAmount(uint256 tokenAmount, bool isDeposit)
        external
        view
        returns (uint256 sharesAmount);
}