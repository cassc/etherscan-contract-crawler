// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISingleSidedInsurancePool {
    function updatePool() external;

    function enterInPool(address _behalf, uint256 _amount) external payable;

    function leaveFromPoolInPending(uint256 _amount) external;

    function leaveFromPending() external;

    function harvest(address _to) external;

    function lpTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function riskPool() external view returns (address);
}