// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IConicOmniPool {
    function depositFor(
        address _account,
        uint256 _amount,
        uint256 _minLpReceived,
        bool stake
    ) external returns (uint256);

    function unstakeAndWithdraw(
        uint256 _conicLpAmount,
        uint256 _minUnderlyingReceived
    ) external returns (uint256);

    function exchangeRate() external view returns (uint256);
}