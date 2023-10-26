// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IDebt {

    function owner() external view returns (address);

    function issueBonds(address recipient, uint256 amount) external;

    function burnBonds(uint256 amount) external;

    function repayLoan(address payer, address recipient, uint256 amount) external;

    function totalDebt() external view returns (uint256);

    function bondsLeft() external view returns (uint256);

    event RepayLoan(
        address indexed receipt,
        uint256 bondsTokenAmount,
        uint256 poolTokenAmount
    );
}