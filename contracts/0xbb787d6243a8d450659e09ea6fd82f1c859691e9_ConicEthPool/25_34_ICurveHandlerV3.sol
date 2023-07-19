// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ICurveHandlerV3 {
    function deposit(address _curvePool, address _token, uint256 _amount) external;

    function withdraw(address _curvePool, address _token, uint256 _amount) external;

    function reentrancyCheck(address _curvePool) external;

    function isReentrantCall(address _curvePool) external returns (bool);
}