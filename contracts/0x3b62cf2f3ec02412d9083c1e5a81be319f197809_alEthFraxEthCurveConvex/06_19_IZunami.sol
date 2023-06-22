//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IStrategy.sol';

interface IZunami {
    function totalDeposited() external returns (uint256);

    function deposited(address account) external returns (uint256);

    function totalHoldings() external returns (uint256);

    function calcManagementFee(uint256 amount) external returns (uint256);

    function delegateDeposit(uint256[3] memory amounts) external;

    function delegateWithdrawal(
        uint256 lpShares,
        uint256[3] memory tokenAmounts,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external;
}