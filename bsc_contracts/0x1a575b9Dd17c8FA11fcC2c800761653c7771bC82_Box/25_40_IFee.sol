// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../Common.sol";

interface IFee {
    error InvalidFeeError();
    error ZeroFeeReceiver();

    event DepositFeeChange(uint256 fee, NameValuePair[] params);
    event WithdrawalFeeChange(uint256 fee, NameValuePair[] params);
    event PerformanceFeeChange(uint256 fee, NameValuePair[] params);
    event FeeReceiverChange(address feeReceiver, NameValuePair[] params);
    event FeeClaim(uint256 fee);

    function getDepositFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function getTotalDepositFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function setDepositFee(uint24 fee, NameValuePair[] calldata params)
        external;

    function getWithdrawalFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function getTotalWithdrawalFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function setWithdrawalFee(uint24 fee, NameValuePair[] calldata params)
        external;

    function getPerformanceFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function getTotalPerformanceFee(NameValuePair[] calldata params)
        external
        view
        returns (uint24);

    function setPerformanceFee(uint24 fee, NameValuePair[] calldata params)
        external;

    function getFeeReceiver(NameValuePair[] calldata params)
        external
        view
        returns (address);

    function setFeeReceiver(
        address feeReceiver,
        NameValuePair[] calldata params
    ) external;

    function claimFee(NameValuePair[] calldata params) external;

    function getCurrentAccumulatedFee() external view returns (uint256);

    function getClaimedFee() external view returns (uint256);
}