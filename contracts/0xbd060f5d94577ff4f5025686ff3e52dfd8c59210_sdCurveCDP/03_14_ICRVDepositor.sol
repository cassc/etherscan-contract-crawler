// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrvDepositor {
    function setGovernance(address _governance) external;

    function setSdTokenOperator(address _operator) external;

    function setGauge(address _gauge) external;

    function setFees(uint256 _lockIncentive) external;

    function lockToken() external;

    function deposit(
        uint256 _amount,
        bool _lock,
        bool _stake,
        address _user
    ) external;

    function depositAll(bool _lock, bool _stake, address _user) external;

    function lockSdveCrvToSdCrv(uint256 _amount) external;
}