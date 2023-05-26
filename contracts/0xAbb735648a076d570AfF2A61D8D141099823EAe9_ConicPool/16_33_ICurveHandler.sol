// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ICurveHandler {
    function deposit(
        address _curvePool,
        address _token,
        uint256 _amount
    ) external;

    function withdraw(
        address _curvePool,
        address _token,
        uint256 _amount
    ) external;
}