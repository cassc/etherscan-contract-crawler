// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IAum.sol";
import "./IFee.sol";
import "./IInvestmentToken.sol";

interface IInvestable is IAum, IFee {
    error ZeroAmountDeposited();
    error ZeroAmountInvested();
    error ZeroAmountWithdrawn();
    error ZeroInvestmentTokenReceiver();
    error ZeroDepositTokenReceiver();
    error TooSmallDepositTokenAmountOut();

    event Deposit(
        address indexed initiator,
        address indexed investmentTokenReceiver,
        uint256 amount
    );
    event Withdrawal(
        address indexed initiator,
        address indexed depositTokenReceiver,
        uint256 amount
    );

    function deposit(
        uint256 depositTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address investmentTokenReceiver,
        NameValuePair[] calldata params
    ) external;

    function withdraw(
        uint256 investmentTokenAmountIn,
        uint256 minimumDepositTokenAmountOut,
        address depositTokenReceiver,
        NameValuePair[] calldata params
    ) external;

    function getDepositToken() external view returns (IERC20Upgradeable);

    function getInvestmentToken() external view returns (IInvestmentToken);

    function setInvestmentToken(IInvestmentToken investmentToken) external;

    function getTotalInvestmentLimit() external view returns (uint256);

    function setTotalInvestmentLimit(uint256 totalInvestmentLimit) external;

    function getInvestmentLimitPerAddress() external view returns (uint256);

    function setInvestmentLimitPerAddress(uint256 investmentLimitPerAddress)
        external;

    function trackingName() external pure returns (string memory);

    function humanReadableName() external pure returns (string memory);

    function version() external pure returns (string memory);
}